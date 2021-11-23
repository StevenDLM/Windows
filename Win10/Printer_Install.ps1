function DriverInstall{
	param ([string]$File,[string]$Name)

	$FileShort = (get-item "$File" -erroraction silentlycontinue).Name
	
	$LocalPath = (get-childitem "C:\Windows\System32\DriverStore\FileRepository" | ?{$_.Name -like "$FileShort*"}).FullName
	
	if(($LocalPath) -AND (Get-PrinterDriver -Name "$Name" -erroraction silentlycontinue)){
		write-host "$Name Driver is already installed"
	}else{
		$PNPmsg = C:\Windows\System32\pnputil.exe /a "$File"
	
		if ($PNPmsg -like "*failed*"){
			write-host "$Name PNPutil FAILED"
			$PNPmsg
			return $FALSE
		}else{
			write-host "$Name PNPutil successful"
			
			Add-PrinterDriver -Name $Name
			write-host "$Name Driver is now installed"
		}
	}
	return $TRUE
	
}

function InstallPrintQueue{
	param ([string]$PrintIP, [string]$PrinterName, [string]$DriverName, [string]$XMLfile)
	
	if (Get-Printer "$PrintName" -erroraction silentlycontinue){
		write-host "$PrintName Printer already installed"
	}else{
		Add-PrinterPort -Name "$PrintIP" -PrinterHostAddress "$PrintIP" -erroraction silentlycontinue
		Add-Printer -Name "$PrinterName" -DriverName "$DriverName" -PortName "$PrintIP" -erroraction silentlycontinue
		
		if (-NOT ($XMLfile -eq "")){
			$XMLconf = get-content $XMLfile -raw
			Set-Printconfiguration -PrinterName "$PrinterName" -PrintTicketXML $XMLconf
		}
		
		Set-Printconfiguration -PrinterName "$PrinterName" -color $FALSE -PaperSize A4
		
		write-host "$PrinterName Printer installed"
	}
	
}


#Remove old Shared Printers
$PrintServer = "PrintSRV01"

#get-printer  * | ?{$_.ComputerName -eq $PrintServer} | remove-printer

#Canon Generiv PCL6 V4 Driver install
$DriverName = "Canon Generic Plus PCL6"
$DriverName
if (DriverInstall "\\FileSRV01\Drivers\Canon_Generic_Plus_PCL6_Driver_V240\Driver\CNP60MA64.INF" $DriverName){

	$LH_XML = "\\FileSRV01\Drivers\LH_Config.xml"
	#Canon C3730 Printer Queues	
	InstallPrintQueue "192.168.123.233" "C3730 (Ground)" $DriverName
	InstallPrintQueue "192.168.123.233" "C3730 LH (Ground)" $DriverName $LH_XML
                      
	InstallPrintQueue "192.168.123.234" "C3730 (Level 1)" $DriverName
	InstallPrintQueue "192.168.123.234" "C3730 LH (Level 1)" $DriverName $LH_XML
                      
	InstallPrintQueue "192.168.123.235" "C3730 (Level 2)" $DriverName
	InstallPrintQueue "192.168.123.235" "C3730 LH (Level 2)" $DriverName $LH_XML
}

#Lexmark Universal PS3 Driver install
$DriverName = "Lexmark Universal v2 PS3"
$DriverName
if (DriverInstall "\\FileSRV01\Drivers\Lexmark\Drivers\Print\GDI\LMUD1N40.inf" $DriverName){

	#Canon C3730 Printer Installs	
	InstallPrintQueue "192.168.123.232" "Lexmark C748DE Colour (Level 1)" $DriverName
}

