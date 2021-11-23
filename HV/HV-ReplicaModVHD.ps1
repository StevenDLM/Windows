
while($VMans -ne "c"){
	Write-host "List of current VMs"

	$i = 0

	write-host "[ID]| VM_Name"
	write-host "----|---------------"
	
	foreach($VM in Get-VM){
		write-host "[$i] $($VM.Name)"
		$i++
	}
	
	write-host "[c] Cancel Script"

	$VMans = Read-Host "Enter VM ID, or enter c to cancel"

	if (($VMans -ne "c") -AND ($VMans -ge 0) -AND ($VMans -lt $i)){
	
		(Get-VM)[$VMans] | fl VMName, State, Path, ReplicationState
		$VMName = (Get-VM).Name[$VMans]

		if((Get-VM $VMName).ReplicationState -ne "Disabled"){

			while($Repans -ne "c"){
			
				Write-Host "Replication is Enabled for these Disk/s"
				(Get-VMReplication $VMName).ReplicatedDisks | ft Path
				
				
				write-host ""
				write-host "[ID]| Option"
				write-host "----|---------------"
				write-host "[a]| Add VHD"
				write-host "[r]| Remove VHD"
				
				$Repans = Read-host "Do you want to add or remove Disks from Replication? or enter c to cancel"
				
				if($Repans -eq "a"){
			
					$i = 0
					
					write-host ""
					write-host "[ID]| VHD_Path"
					write-host "----|---------------"
					foreach($VDisk in (get-vmreplication $VMName).ExcludedDisks | ?{$_.Path -like "*.vhdx"}){
						
						write-host "[$i] $($VDisk.Path)"
						$i++
					}
					
					write-host "[c] Cancel Script"
					write-host ""

					write-host "AVHD files"
					write-host "------------------"
					
					foreach($VDisk in ((get-vmreplication $VMName).ExcludedDisks | ?{-NOT ($_.Path -like "*.vhdx")})){

						write-host "[-] $($VDisk.Path)"

					}

					$ans = Read-Host "Select Drive to add to Replication, or enter c to cancel"

					if (($ans -ne "c") -AND ($ans -ge 0) -AND ($ans -lt $i)){
						$RepList = (get-vmreplication $VMName).ReplicatedDisks
						$RepList += (get-vmreplication $VMName).ExcludedDisks[$ans]

						Set-VMreplication $VMName -ReplicatedDisks ($RepList)
					}else{
					
						if ($ans -ne "c"){
						
							Write-Host "Invalid Entry, Try Again"
							cls
						
						}
					
					}
				}else{
				
					if($Repans -eq "r"){
					
						$i = 0
						
						write-host ""
						write-host "[ID]| VHD_Path"
						write-host "----|---------------"
						foreach($VDisk in (get-vmreplication $VMName).ReplicatedDisks | ?{$_.Path -like "*.vhdx"}){
							
							write-host "[$i] $($VDisk.Path)"
							$i++
						}
						
						write-host "[c] Cancel Script"
						write-host ""

						$ans = Read-Host "Select Drive to remove from Replication, or enter c to cancel"

						if (($ans -ne "c") -AND ($ans -ge 0) -AND ($ans -lt $i)){
						
							$RepList = @()
							
							foreach($RepDisk in ((get-vmreplication $VMName).ReplicatedDisks | ?{$_.Path -ne ((get-vmreplication $VMName).ReplicatedDisks[$ans]).path})){
							
								$RepList += $RepDisk
							
							}

							Set-VMreplication $VMName -ReplicatedDisks ($RepList) -whatif
							
						}else{
						
							if ($ans -ne "c"){
							
								Write-Host "Invalid Entry, Try Again"
								cls
							
							}
						}
					}				
				}
			}
		}else{

			write-host "Replication NOT Enabled on this VM"
			
		}
	}else{
	
	Write-Host "Invalid Entry, Try Again"
	cls
	
	}
	

	
}
