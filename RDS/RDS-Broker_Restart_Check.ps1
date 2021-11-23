param
($CollectionName, $EmailTo, $LogPath)

write-host "Getting Ready..."

$DayName = ((get-date).dayofweek).tostring().substring(0,3)
$DayName = "Test"
$LogName = "$LogPath\RDS_Broker-$DayName.log"

start-transcript "$LogName"

####Broker Restart and Check####
#restart-service tssdis
#sleep 300

write-host "Scraping Recent Broker Connection Events..."

$EmailEvents = "Time | Event`n"
$BrokerEvents = (get-winevent -logname "Microsoft-Windows-TerminalServices-SessionBroker/Operational" | ?{($_.Id -eq '776') -AND ($_.TimeCreated -gt (Get-Date).addMinutes(-15))})
foreach($event in $BrokerEvents){

$EmailEvents += "$($event.TimeCreated) | $($event.Message.substring(65,49).trim())`n"

}

write-output $EmailEvents

write-host "Checking Open Connections..."

$OpenConns = (netstat -ano | findstr (get-process tssdis).id).replace("TCP    ","`n")

write-output $OpenConns

####Live User List####

write-host "Fetching List of Live Users in $CollectionName..."

foreach ($ServerName in (Get-RDSessionHost $CollectionName | sort SessionHost).SessionHost){
	write-host "-------------------------"
	write-output $ServerName
	write-host "-------------------------"

	$queryResults = (qwinsta /server:$ServerName | foreach {
		if(($_.substring(0,8).trim() -eq "SESSION")){
			$obj = "ServerName,"
		}else{
			$obj = "$ServerName,"
			if($_.substring(0,8).trim() -ne "rdp-tcp"){
				$obj = "$obj,"
			}
		}
		$obj = $obj + ($_.trim() -replace "\s+",",")
		$obj
	}
	)
	
	$queryObjs = ($queryResults | convertfrom-csv) | ?{($_.USERNAME -ne "services") -AND ($_.USERNAME -ne "65536") -AND ($_.USERNAME -ne "console")}
	

	write-host "Users Connected:" ($queryObjs | ?{($_.State -ne "Disc")}).count -NoNewLine
	write-host " | Users Disconnected:" ($queryObjs | ?{($_.State -eq "Disc")}).count
	
	$queryObjs | sort State | ft username, ID, State
	
}

####RegCheck####

write-host "Checking for .BAK entries on Session Hosts..."

$BAKList =  @()
$UserList = @()
$UPDList = @()

$DC = (Resolve-DNSName (Get-DnsClientServerAddress)[0].serveraddresses[0]).NameHost
$S = New-PSSession -computername $DC
Import-Module -PSSession $S -Name activedirectory


foreach ($ServerName in (Get-RDSessionHost $CollectionName | sort SessionHost).SessionHost){

	write-host "Checking $ServerName"

	$BAKRegKey = invoke-command -ComputerName $ServerName {(get-childitem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | ?{$_.name -like "*S-1-5-21-1976179875-158503342-2709918559-*.bak"})}
	
	if ($BAKRegKey){
		$BAKRegKey = $BAKRegKey.Name.substring(76).trim()
	}
	write-host "> Found $($BAKRegKey.count) BAK profiles"

	if($BAKRegKey){
		foreach($RegKey in $BAKRegKey){
		
			$ProfPath = invoke-command -ComputerName $ServerName -argument $RegKey {param($RegKey) (get-item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$RegKey").GetValue("ProfileImagePath")}
			
			$BAK_Stats = New-Object -TypeName PSObject
			$BAK_Stats | Add-Member -MemberType NoteProperty -Name Server $ServerName
			$BAK_Stats | Add-Member -MemberType NoteProperty -Name RegKey $RegKey
			$BAK_Stats | Add-Member -MemberType NoteProperty -Name ProfilePath -Value $ProfPath
			
			$BAKList += $BAK_Stats
		}
	}
}

if($BAKList.count -eq 0){
	Write-host "No BAK Entries Found"
}else{

	foreach($UserSID in ($BAKList.RegKey) -replace ".bak",""){

		$UserList += Get-ADUser -Filter * | ?{$_.SID -like "$UserSID"} | Select Name, SamAccountName, SID
		
		$UPDServer = (Get-RDSessionCollectionConfiguration $CollectionName -UserProfileDisk).DiskPath.substring(2)
		$UPDServer = $UPDServer.substring(0,$UPDServer.indexof("\"))
		$OpenUPD = invoke-command -computername $UPDServer -argument $UserSID {param($UserSID) Get-SmbOpenFile | ?{$_.ShareRelativePath -like "*$UserSID*"}}
		
		if ($OpenUPD){
			$UPDList += $OpenUPD | select ShareRelativePath, ClientUsername
		}

	}
}

SLEEP 2

write-host "-------------------------"
write-host "BAK entries in the Registry Profile List"
write-host "-------------------------"
write-output $BAKList | ft

SLEEP 2
write-host "-------------------------"
write-host "Associated Users"
write-host "-------------------------"
write-output $UserList | ft

SLEEP 2
write-host "-------------------------"
write-host "Associated Open UPDs"
write-host "-------------------------"
write-output $UPDList | ft

##End and Email
stop-transcript 

Send-MailMessage -SmtpServer "mail.becampbell.com.au" -From "BECRDSBRK01@becampbell.com.au" -To $EmailTo -Subject ("BEC - VTS Connectivity [123-336217]") -Body ($EmailEvents + "`n`n" + $OpenConns) -attachments "$LogName"
