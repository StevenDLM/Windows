Function StartUp(){
	$logfile = (Get-Date -format yyyyMMdd) + "_" + (Get-Date -format hhmm) + "_Exc-AiO.log"
	start-transcript $logfile
	
	if (-NOT (YesNo "Running" "Exchange Shell as Admin?")){
	exit
	}
	
	$Server =  Read-Host " Specify Server Name"
	
	$Version = YesNo "Running" "Exchange 2016?"
	
	Do{
		cls
		CheckDir($Server)	
		cls
		$Repeat = Menu $Server $Version
	}While ($Repeat -eq $TRUE)
	stop-transcript
}

Function Menu($HostName, $Ver){
	
	if ($Ver){
		$menuList = @"
Exchange Config Items
1. Update Internal/External Domain Names
2. Update Logon Method
3. Update Autodiscover and OAB
4. Enable Remote Powershell
5. Add Default Send Connector
6. Add App Relay Receive Connector
7. Add Accepted Domains
8. Set Mailbox Size
9. Set Max Send/Receive Size
10. Set Import/Export Role
11. Set MAPI over HTTP
99. New Setup Wizard
0. Quit Script
"@
		$menuNum = 11
	}else{
		$menuList = @"
Exchange Config Items
1. Update Internal/External Domain Names
2. Update Logon Method
3. Update Autodiscover and OAB
4. Enable Remote Powershell
5. Add Default Send Connector
6. Add App Relay Receive Connector
7. Add Accepted Domains
8. Set Mailbox Size
9. Set Max Send/Receive Size
10. Set Import/Export Role
99. New Setup Wizard
0. Quit Script
"@
		$menuNum = 10
	}
	write-host "Exchange All-in-One" -ForegroundColor Cyan
	write-host $menuList
	$Option = Read-Host "Select Menu Number [0-$menuNum,99]"
	
	Switch ($Option){
		1{
			UpdateDomains($HostName)
		}
		2{
			UpdateLogon($HostName)
		}
		3{
			UpdateAutodiscover($HostName)
		}
		4{
			EnableRemotePS
		}
		5{
			AddSendConnector($Ver)
		}
		6{
			AddAppRelay($HostName)
		}
		7{
			AddAcceptDomain
		}
		8{
			SetMbxSize
		}
		9{
			SetMaxSR
		}
		10{
			SetImExRole
		}
		11{
			if($Ver){SetMapi($HostName)}
		}
		99{
			UpdateDomains($HostName)
			UpdateLogon($HostName)
			UpdateAutodiscover($HostName)
			EnableRemotePS
			AddSendConnector($Ver)
			AddAppRelay($HostName)
			AddAcceptDomain
			SetMbxSize
			SetMaxSR
			SetImExRole
			SetMapi($HostName)
		}
		0{
			iisreset
			cls
			"...Final Result..."
			CheckDir($HostName)

			Return $FALSE
		}
		
	}

	Return $TRUE
	
}

Function YesNo($caption,$message){

	$yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","help"
	$no = new-Object System.Management.Automation.Host.ChoiceDescription "&No","help"
	$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
	$answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

	$answer = (-Not $answer)
	$answer
}

Function CheckDir([String] $ServerName){

	"...Current VDir Settings.."
	Get-ClientAccessServer -Identity $ServerName | fl Identity,AutodiscoverServiceInternalUri
	Get-WebServicesVirtualDirectory -Identity "$ServerName\EWS (Default Web Site)" | fl Identity,InternalUrl,ExternalUrl
	Get-OABVirtualDirectory -Identity "$ServerName\oab (Default Web Site)" | fl Identity,InternalUrl,ExternalUrl
	Get-ActiveSyncVirtualDirectory -Identity "$ServerName\Microsoft-Server-ActiveSync (Default Web Site)" | fl Identity,InternalUrl,ExternalUrl
	Get-OWAVirtualDirectory -Identity "$ServerName\owa (Default Web Site)" | fl Identity,InternalUrl,LogonFormat
	Get-ECPVirtualDirectory -Identity "$ServerName\ecp (Default Web Site)" | fl Identity,InternalUrl,ExternalUrl
	
	"...Current MAPI over HTTP Settings.."
	Get-MapiVirtualDirectory -Identity "$ServerName\mapi (Default Web Site)" | fl Identity,InternalUrl,ExternalUrl
	
	"...Current OutlookAnywhere Settings.."
	Get-OutlookAnywhere -Identity "$ServerName\Rpc (Default Web Site)" | fl InternalHostName,ExternalHostName
	
	"...Current Powershell Permissions.."
	Get-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -PSPath "IIS:\" -Location "Default Web Site/Powershell"
	
	"...Current Connector Settings.."
	Get-ReceiveConnector | fl identity, RemoteIPRanges, Bindings, Usage, TransportRole, AuthMechanism, PermissionGroups, Enabled
	Get-SendConnector | fl identity, addressspaces, enabled, MaxMessageSize
	
	"...Current Accepted Domains.."
	Get-AcceptedDomain
}

Function UpdateDomains([String] $ServerName){
	
	$Domain = Read-Host "Specify External Domain Name"
	
	"...Setting Exchange Domains..."
	Set-ClientAccessServer -Identity "$ServerName" -AutodiscoverServiceInternalUri https://$Domain/autodiscover/autodiscover.xml
	Set-WebServicesVirtualDirectory -Identity "$ServerName\EWS (Default Web Site)" -InternalUrl https://$Domain/ews/exchange.asmx -ExternalUrl https://$Domain/EWS/exchange.asmx
	Set-OABVirtualDirectory -Identity "$ServerName\oab (Default Web Site)" -InternalUrl https://$Domain/oab -ExternalUrl https://$Domain/oab
	Set-ActiveSyncVirtualDirectory -Identity "$ServerName\Microsoft-Server-ActiveSync (Default Web Site)" -InternalUrl https://$Domain/Microsoft-Server-ActiveSync -ExternalUrl https://$Domain/Microsoft-Server-ActiveSync
	Set-OWAVirtualDirectory -Identity "$ServerName\owa (Default Web Site)" -InternalUrl https://$Domain/owa
	
	Set-ECPVirtualDirectory -Identity "$ServerName\ecp (Default Web Site)" -InternalUrl https://$Domain/ecp -ExternalUrl https://$Domain/ecp -BasicAuthentication $True -WindowsAuthentication $False -FormsAuthentication $True
}

Function SetMapi($ServerName){
	
	$Domain = Read-Host "Specify External Domain Name"
	
	"...Configuring MAPI over HTTP..."
	
	$mapiAuth = @("Basic","NTLM", "OAuth","Negotiate")
	Set-MapiVirtualDirectory -Identity "$ServerName\mapi (Default Web Site)" -InternalUrl https://$Domain/mapi -ExternalUrl https://$Domain/mapi -IISAuthenticationMethods $mapiAuth
	Set-OrganizationConfig -MapiHttpEnabled $true
}


Function UpdateLogon([String] $ServerName){
		"...Setting logon method for OWA..."
		$NetBios = Read-Host "Set NetBios Domain for logon"
		Set-OwaVirtualDirectory "$ServerName\owa (Default Web Site)" -LogonFormat Username -DefaultDomain $NetBios
}
	
	
Function UpdateAutodiscover([String] $ServerName){
	
	$Domain = Read-Host "Specify External Domain Name"
	
	"...Setting Autodiscover and OAB..."
	
	Set-OutlookAnywhere -Identity "$ServerName\Rpc (Default Web Site)" -InternalHostName $Domain -InternalClientsRequireSsl $true -ExternalHostName $Domain -ExternalClientsRequireSsl $true -ExternalClientAuthenticationMethod Negotiate
}

Function EnableRemotePS(){
		
		$User = Read-Host "Enter Username"
		
		"...Granting Remote Powershell Rights..."
		
		Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -Value True -PSPath "IIS:\" -Location "Default Web Site/Powershell"
		Enable-PSRemoting -force
		Set-User $User -RemotePowerShellEnabled $True
		
}

Function AddSendConnector($Ver){

		"...Creating Send Connector..."
		
		if ($Ver){
			New-SendConnector -Name "Default Internet" -AddressSpaces * -DNSRoutingEnabled $TRUE
		}else{
			New-SendConnector -Name 'Default Internet' -RemoteIPRanges @(SMTP:*;1)
		}
		
}

Function AddAppRelay([String] $ServerName){
		
		$RelayIPs = @(Read-Host "Enter IP to Relay")
		
		While (YesNo("Add"," Another IP to Relay?")){
			$RelayIPs += Read-Host "Enter IP to Relay"
		}
		
		"...Creating Receive Connector..."
		
		New-ReceiveConnector -Name 'App Relay' -RemoteIPRanges $RelayIPs -Bindings @('0.0.0.0:25') -Usage 'Custom' -Server $ServerName -TransportRole 'FrontendTransport' -AuthMechanism "ExternalAuthoritative" -PermissionGroups "AnonymousUsers, ExchangeServers"
}

Function AddAcceptDomain(){

	$AccAgain = $True
	while ($AccAgain){
		$AccDomain = Read-Host "Enter New Accepted Domain Name"
		$AccDefault = (YesNo("Set as","Default Accepted Domain?"))
		if (Get-AcceptedDomain | ?{$_.DomainName -eq $AccDomain}){
			"...Creating Accepted Domain..."
			New-AcceptedDomain -Name $AccDomain -DomainName $AccDomain -DomainType "Authoritative"
			Set-AcceptedDomain -Identity $AccDomain -MakeDefault $AccDefault
		}else{
			"Domain Already Exists"
		}
		$AccAgain = (YesNo("Add","another Accepted Domain?"))
	}
	
	if (YesNo("Update","Address Policy to Accepted Domain?"))
	{
		"Not Implemented yet"
	}
}

Function SetMbxSize(){
	
	$MbxSize = Read-Host "Enter Default Mailbox Size (in GB)"
	
	$MbxWarn = $MbxSize - 1
	$MbxWarn = "$MbxWarn" + "GB"
	
	$MbxSize = "$MbxSize" + "GB"
	
	Set-MailboxDatabase -ProhibitSendReceiveQuota $MbxSize -ProhibitSendQuota $MbxSize -IssueWarningQuota $MbxWarn

}

Function SetMaxSR()
{
		$MaxSize = Read-Host "Enter Max Send/Receive Size (in MB)"
		$MaxSize = "$MaxSize" + "MB"
		Set-TransportConfig -MaxSendSize $MaxSize -MaxReceiveSize $MaxSize
		Get-ReceiveConnector | Set-ReceiveConnector -MaxMessageSize $MaxSize
		Get-SendConnector | Set-SendConnector -MaxMessageSize $MaxSize
}

Function SetImExRole(){

		$VanDelay = Read-Host "Enter Username for Importer/Exporter Role"
		
		"...Assigning Import/Export Roles..."
		New-ManagementRoleAssignment -Role "Mailbox Import Export" -User $VanDelay
}


Function BrowserSecurity(){

	"..Adding Browser Security Registry Keys..."
	
	reg add "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002" /v Functions /t REG_SZ /d "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_3DES_EDE_CBC_SHA"

	reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Microsoft\Cryptography\Configuration\SSL\00010002" /v Functions /t REG_SZ /d "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_3DES_EDE_CBC_SHA"

	reg add "HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" /v Enabled /t REG_DWORD /d 0xFFFFFFFF
	reg add "HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v Enabled /t REG_DWORD /d 0xFFFFFFFF
	reg add "HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v Enabled /t REG_DWORD /d 0xFFFFFFFF
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" /v Enabled /t REG_DWORD /d 0xFFFFFFFF
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v Enabled /t REG_DWORD /d 0xFFFFFFFF
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v Enabled /t REG_DWORD /d 0xFFFFFFFF

}

#Menu
StartUp
