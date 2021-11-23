
Params($PathOU = "OU=Groups,OU=Root,DC=sfg,DC=cc,DC=com,DC=au", $TargetOU = "OU=Office365,OU=Groups,OU=Root,DC=sfg,DC=cc,DC=com,DC=au")

Import-Module MSOnline
Import-Module ActiveDirectory
Connect-MsolService

#List of groups in O365
$O365Groups = Get-MsolGroup -All | Where-Object {$_.DisplayName -notlike "*.onmicrosoft.com" -AND $_.GroupType -ne "Security"}


foreach ($O365Group in $O365Groups) {
	$ADGroup = Get-ADGroup -Filter "Name -eq '$($O365Group.DisplayName)'"
	try {
		if ($ADGroup) {
			Write-Output "EXISTS: $($ADGroup.Name)"
		} else {
			Write-Output "CREATE: $($O365Group.DisplayName)"
			$Mail = $($O365Group.ProxyAddresses | Where-Object {$_ -cmatch "^SMTP"}).substring(5)
			New-ADGroup -Path $TargetOU `
				-Name $O365Group.DisplayName `
				-SamAccountName $O365Group.DisplayName `
				-OtherAttributes @{ProxyAddresses=[string[]]$O365Group.ProxyAddresses} `
				-GroupScope Global `
				-Description "Imported from O365" `
				-GroupCategory Distribution `
				-whatif -confirm `
				-ErrorAction Stop -WarningAction Stop
			
			$GroupMembers = Get-MsolGroupMember -GroupObjectID "$($O365Group.ObjectID)"
			Add-ADGroupMember -identity $O365Group.DisplayName -Members ($GroupMembers.EmailAddress -replace '@cc.com.au','')
		}
	} catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException] {
			Write-Warning "Error when updating ImmutableID"
	} catch {
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		Write-Warning "Error when creating group $($O365Group.DisplayName): $ErrorMessage"
	}
}
   
   
