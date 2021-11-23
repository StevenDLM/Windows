Param([string]$logPath = 'C:\ProgramData\Logfiles', [string]$TopFolder, [string]$DOMAIN = "CLI")

#Start logging
$date = Get-Date -format HHmm_ddMMyy
Start-Transcript "$logPath\PermUser-$date.log" -Append

#Find list of all folders
$allFolders = Get-ChildItem $TopFolder

#Create security object for CLIAdmin
$aclOwner = new-object System.Security.AccessControl.DirectorySecurity
$aclOwner.SetOwner([System.Security.Principal.NTAccount]"$DOMAIN\CLIAdmin")

$Owner = (Get-Acl $TopFolder).Owner
if($Owner -ne "$DOMAIN\CLIAdmin"){
	"Changing Owner from $Owner"
	Set-Acl $TopFolder $aclOwner
}

$aclTopFolder = new-object System.Security.AccessControl.DirectorySecurity
$addPerm = @(("CREATOR OWNER","FullControl"),("BUILTIN\Administrators","FullControl"),("SYSTEM","FullControl"),("$DOMAIN\CLIAdmin","FullControl"),("$DOMAIN\Domain Users","Read"))

foreach($x in 0..($addPerm.Length-1)){
	$Ar0 = New-Object system.security.accesscontrol.filesystemaccessrule($addPerm[$x][0],$addPerm[$x][1], "ContainerInherit,ObjectInherit", "None","Allow")
	$aclTopFolder.SetAccessRule($Ar0)
}

#Set Default Perms at Top Level
Set-Acl $TopFolder $aclTopFolder

#Disable Inheritance at Top Level
$Inherit = Get-NTFSAccess $TopFolder | findStr "Path:"
if($Inherit -LIKE "*enabled*"){
	"Disabling Inheritance on $TopFolder"
	Disable-NTFSAccessInheritance $TopFolder -RemoveInheritedAccessRules
}

$aclAllFolders = new-object System.Security.AccessControl.DirectorySecurity
$addPerm = @(("CREATOR OWNER","FullControl"),("BUILTIN\Administrators","FullControl"),("SYSTEM","FullControl"),("$DOMAIN\CLIAdmin","FullControl"))
foreach($x in 0..($addPerm.Length-1)){
	$Ar1 = New-Object system.security.accesscontrol.filesystemaccessrule($addPerm[$x][0],$addPerm[$x][1], "ContainerInherit,ObjectInherit", "None","Allow")
	$aclAllFolders.SetAccessRule($Ar1)
}


#Apply Ownership or Inheritance to $allFolders
$i = 1
foreach($Folder in $allFolders){
	$path = $Folder.FullName
	$Name = $Folder.Name
	$percent = [math]::Round($i / $allFolders.count*100 , 2)
	Write-Progress -Activity "Checking/Setting Permissions on all folder" -status "${percent}% | Modifying file/folder: $path" -percentComplete $percent
	Write-Host "Checking: $path"
	$i++

	$Owner = (Get-Acl $path).Owner
	if($Owner -ne "$DOMAIN\CLIAdmin"){
		"Changing Owner"
		Set-Acl $path $aclOwner
	}

	$aclUserFolder = new-object System.Security.AccessControl.DirectorySecurity
	$user = "$DOMAIN\$Name"
	$addPerm = @(("CREATOR OWNER","FullControl"),("BUILTIN\Administrators","FullControl"),("SYSTEM","FullControl"),("$DOMAIN\CLIAdmin","FullControl"),($user,"Modify"))
	foreach($x in 0..($addPerm.Length-1)){
		$Ar1 = New-Object system.security.accesscontrol.filesystemaccessrule($addPerm[$x][0],$addPerm[$x][1], "ContainerInherit,ObjectInherit", "None","Allow")
		$aclUserFolder.SetAccessRule($Ar1)
	}

	
	Set-Acl $path $aclUserFolder
	
	$Inherit = Get-NTFSAccess $path | findStr "Path:"
	if($Inherit -LIKE "*enabled*"){
		"Disabling Inheritance"
		Disable-NTFSAccessInheritance $path -RemoveInheritedAccessRules
	}
}

stop-transcript
