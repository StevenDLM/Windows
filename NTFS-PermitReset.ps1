Param([string]$logPath = 'C:\ProgramData\Logfiles', [string]$dstFolder, [string]$DOMAIN = "CLI")

#Start logging
$date = Get-Date -format yyMMdd
Start-Transcript "$logPath\$date-SharePerm.log" -Append

#Find list of all folders for limited perms , then subfolders for increased access
$allFolders = (Get-ChildItem $dstFolder -Recurse).FullName
$subFolders = (Get-Item $dstFolder\*\*).FullName

#Create blank security object
$aclOwner = new-object System.Security.AccessControl.DirectorySecurity
$aclOwner.SetOwner([System.Security.Principal.NTAccount]"$DOMAIN\CLIAdmin")

#Apply Ownership or Inheritance to $allFolders
$i = 1
foreach($path in $allFolders){
	$percent = [math]::Round($i / $allFolders.count*100 , 2)
	#Write-Progress -Activity “Part 1 of 2: Checking/Setting Ownership and Inheritance on all files” -status “Modifying file/folder: $path” ` -percentComplete $percent
	“${percent}% | Checking file/folder: $path”
	$i++

	$Owner = (Get-Acl $path).Owner
	if($Owner -ne "$DOMAIN\CLIAdmin"){
		"Changing Owner from $Owner"
		Set-Acl $path $aclOwner
	}

	$Inherit = Get-NTFSAccess $path | findStr "Path:"
	if($Inherit -LIKE "*disabled*"){
		"Enabling Inheritance"
		Enable-NTFSAccessInheritance $path
	}

}

#List of Users and Permission Levels stored in $addPerm
$aclUsersRead = new-object System.Security.AccessControl.DirectorySecurity
$addPerm = @(("BUILTIN\Administrators","FullControl"),("SYSTEM","FullControl"),("$DOMAIN\CLIAdmin","FullControl"),("$DOMAIN\Power_Users","Modify"),("$DOMAIN\Domain Users","ReadandExecute"))

#Update $Acl with $addPerm
foreach($x in 0..($addPerm.Length-1)){
	$Ar = New-Object system.security.accesscontrol.filesystemaccessrule($addPerm[$x][0],$addPerm[$x][1], "ContainerInherit,ObjectInherit", "None","Allow")
	$aclUsersRead.SetAccessRule($Ar)
}

#Set Permissions in Top Level folder
$Owner = (Get-Acl $dstFolder).Owner
if($Owner -ne "$DOMAIN\CLIAdmin"){
	"Setting Owner on $dstFolder"
	Set-Acl $dstFolder $aclOwner
}

$Owner = (Get-Acl $dstFolder).AccessToString
if($Owner -ne $aclUsers.AccessToString){
	"Setting Users on $dstFolder"
	Set-Acl $dstFolder $aclUsersRead
}

$Inherit = Get-NTFSAccess $dstFolder | findStr "Path:"
if($Inherit -LIKE "*enabled*"){
	"Disabling Inheritance on $dstFolder"
	Disable-NTFSAccessInheritance $dstFolder -RemoveInheritedAccessRules
}

#Update $Acl to allow Modify for Domain Users
$aclUsersMod = new-object System.Security.AccessControl.DirectorySecurity
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule("$DOMAIN\Domain Users","Modify", "ContainerInherit,ObjectInherit", "InheritOnly", "Allow")
$aclUsersMod.SetAccessRule($Ar)

#Apply updated $Acl to all 2nd level $subFolders
$i = 1
foreach($path in $subFolders){
	$percent = [math]::Round($i / $subFolders.count*100 , 2)
	Write-Progress -Activity “Part 2 of 2: Adding Modify Permissions to 2nd Level Folders” -status “Modifying folder: $path” ` -percentComplete $percent
	$i++
	"${percent}% | Modifying folder: $path"
	Set-Acl $path $aclUsersMod
}

Stop-Transcript
