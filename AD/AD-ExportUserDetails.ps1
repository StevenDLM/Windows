Param([string]$FilePath = "C:\Temp\", [string]$OU = "OU=Root,DC=CLI,DC=com,DC=au")

$Hostname = hostname

if(-NOT (Test-Path $FilePath)){
	New-Item -Path $FilePath -ItemType Directory 
}
$File_Users = $FilePath + $Hostname + "_AD_Users_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"
$File_Groups = $FilePath + $Hostname + "_AD_Groups_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"
$File_Alias = $FilePath + $Hostname + "_AD_Alias_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"

$GroupList = [System.Collections.ArrayList]@()

foreach($User in (Get-AdUser -SearchBase $OU -filter 'enabled -eq $true' -properties *)){

	$AD_User_Stats = New-Object -TypeName PSObject
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name Name $User.Name
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name DistinguishedName $User.DistinguishedName
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name Created $User.Created
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name UserPrincipalName $User.UserPrincipalName
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name ScriptPath $User.ScriptPath
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name ProfilePath $User.ProfilePath
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name HomeDrive $User.HomeDrive
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name HomeDirectory $User.HomeDirectory
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name PasswordLastSet $User.PasswordLastSet
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name PasswordNeverExpires $User.PasswordNeverExpires
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name logonCount $User.logonCount
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name LastBadPasswordAttempt $User.LastBadPasswordAttempt
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name LockedOut $User.LockedOut
	$AD_User_Stats | Add-Member -MemberType NoteProperty -Name lastLogonDate $User.lastLogonDate
		
	Export-Csv $File_Users -InputObject $AD_User_Stats -Append -NoTypeInformation -Force
	
	foreach($UserGroup in $user.MemberOf){
		$GroupListed = $FALSE
		foreach($ListGroup in $GroupList){
			if($UserGroup -eq $ListGroup){
				$GroupListed = $TRUE	
			}
		}
		if(-NOT $GroupListed){
			$GroupList.add($UserGroup) | out-null
		}
		
		$AD_Groups = New-Object -TypeName PSObject
		$AD_Groups | Add-Member -MemberType NoteProperty -Name Name $User.Name
		$AD_Groups | Add-Member -MemberType NoteProperty -Name Group $UserGroup
		
		Export-Csv $File_Groups -InputObject $AD_Groups -Append -NoTypeInformation -Force

	}
	
	foreach($UserAlias in $user.proxyAddresses){
		
		$AD_Alias = New-Object -TypeName PSObject
		$AD_Alias | Add-Member -MemberType NoteProperty -Name Name $User.Name
		$AD_Alias | Add-Member -MemberType NoteProperty -Name Alias $UserAlias
		
		Export-Csv $File_Alias -InputObject $AD_Alias -Append -NoTypeInformation -Force

	}
	
}

write-host "VM Specs stored: $File_Users"
write-host "VM Specs stored: $File_Groups"
write-host "VM Specs stored: $File_Alias"
