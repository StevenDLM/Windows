Param(
[string]$IPadress,
[string]$AdoptURL,
[string]$SSHpass)

$Creds = New-Object System.Management.Automation.PSCredential ('admin', $(ConvertTo-SecureString $SSHpass -AsPlainText -Force))
	
		New-SSHSession -ComputerName $IPadress -Credential $Creds -Force | out-null
		$session = Get-SSHSession -Index 0
		$stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
		$stream.Write("set-inform $AdoptURL`n")
		start-sleep -s 2
		$stream.Write("set-inform $AdoptURL`n")
		Remove-SSHSession 0 | out-null
