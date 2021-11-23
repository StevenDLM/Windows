#Function to emulate the Yes/No Prompt at start of script.
Function YesNo($caption,$message){

	$yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","help"
	$no = new-Object System.Management.Automation.Host.ChoiceDescription "&No","help"
	$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
	$answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

	$answer = (-Not $answer)
	$answer
}

#Creates Transscript File name and initiates transcript
$logfile = "C:\Temp\" + (Get-Date -format yyyyMMdd_hhmm) + "_HV-OptimiseVHD.log"
start-transcript $logfile

#Gets list of Vms and outputs a table with associated ID numbers
$VMs = get-vm
$VMsList = "ID`tVM name`n--------------------"
$i = 0


#Get current VM Disk Usage and Provisioned Space
$ProvSpace = 0
$UsedSpace = 0
foreach($VM in get-vm){
	$VM.Name
	$VHDs = (get-vmharddiskdrive $VM).Path | Get-VHD
	foreach($VHD in $VHDs){
		$VHD | Select Path, @{label=’File Size(GB)’;expression={$_.filesize/1gb –as [int]}}, @{label=’Max Size(GB)’;expression={$_.size/1gb –as [int]}}
		$ProvSpace = $ProvSpace + ($VHD.size/1gb –as [int])
		$UsedSpace = $UsedSpace + ($VHD.filesize/1gb –as [int])
	}
}
"Total Used Space: " + $UsedSpace + "GB"
"Total Provisioned Space: " + $ProvSpace + "GB"


foreach($VM in $VMs){$VMsList = $VMsList + "`n" + $i + "`t" + $VM.Name; $i++}

#Asks Yes/No to Optimise all VMs
#If you do, it confirms any exceptions
#If you don't, it requests you to select a VM
if(YesNo("Optimise","VHD Files across all VMs?")){
	
	While(YesNo("Exclude","any other VMs?")){
		cls
		echo $VMsList
		[uint16]$ExcVM = Read-Host "Enter VM ID to exclude"
		if (($ExcVM -ge 0) -AND ($ExcVM -lt $VMs.count)){
			write-host $VMs[$ExcVM].Name "will be excluded"
			$VMs = $VMs | ?{$_.Name -ne $VMs[$ExcVM].Name}
			$VMsList = "ID`tVM name`n--------------------"
			$i = 0
			foreach($VM in $VMs){$VMsList = $VMsList + "`n" + $i + "`t" + $VM.Name; $i++}
			
		}else{
			write-host "Selection Outside of range" -foregroundcolor red -backgroundcolor black
		}
		
	}
}else{
	cls
	echo $VMsList
	[uint16]$OneVM = Read-Host "Enter VM ID to Optimise"
	While(($OneVM -lt 0) -OR ($OneVM -ge $VMs.count)){
		cls
		write-host "Selection Outside of range" -foregroundcolor red -backgroundcolor black
		echo $VMsList
		[uint16]$OneVM = Read-Host "Enter VM ID to Optimise"
	}
	$VMs = $VMs[$OneVM]
	write-host $VMs.Name "will be optimised"
}

"Task Started"

#For every VM previously specififed, if the VM is running it is shutdown
#Each VHDx file connected to that VM is then Mounted, Optimised and Dismounted
#If the VM was running initially, it is then started again.
foreach($VM in $VMs){
	$StartedOn = $FALSE
	if ($VM.State -ne "Off"){
		"Shutting Down "+$VM.Name
		$StartedOn = $TRUE
		Stop-VM $VM -force
	}
    $VHDs = (get-vmharddiskdrive $VM).Path
    foreach($VHD in $VHDs){
		"Optimising Disk: $VHD"
        Mount-VHD $VHD -ReadOnly
        Optimize-VHD $VHD -Mode full
        Dismount-VHD $VHD
		"Disk Optimised"
    }
	If ($StartedOn){
		"Starting Up "+$VM.Name
		Start-VM $VM
	}
}
"Task Complete"
#Job Done. Ending Transcript
stop-transcript
