
##Part1##
#CSV List of Users to be Disabled
$Users = get-content C:\Temp\DisableUsers.csv

foreach($User in $Users){
	#Gets ADUser, disables and hides them from AddressBook, and moves their OU
  $Username = Get-ADUser -filter * -searchbase "OU=Users,OU=Root,DC=sfg,DC=cc,DC=com,DC=au" | ?{$_.Name -eq "$User"}
	Set-ADUser "$($Username.SamAccountName)" -Enabled $FALSE -Add @{"msExchHideFromAddressLists"="TRUE"}
	Move-ADObject -Identity "$($Username.ObjectGUID)" -TargetPath "OU=Disabled,OU=Users,OU=Root,DC=sfg,DC=cc,DC=com,DC=au"
	
  #Appends ADUser Username to new CSV
	"$($Username.SamAccountName)" >> C:\Temp\DisabledUserList.csv
}

##Part2##
#CSV List of Users Disabled in AD
$Usernames = get-content C:\Temp\DisabledUserList.csv

#Connects to Exchange Online
$LiveCred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session

#Connects to MSOnline
Install-Module MSOnline
Import-Module MSOnline
Connect-MsolService

foreach($User in $Usernames){
  #Coverts all Disabled Users to Shared Mailboxes
  Set-Mailbox "$User" -Type shared

  #Removes licensing from all Disabled users
	foreach($Lic in (get-msoluser -userprincipalname "$User").Licenses.AccountSkuId){
		Set-MsolUserLicense -UserPrincipalName "$User" -RemoveLicenses "$Lic"
	}
}

