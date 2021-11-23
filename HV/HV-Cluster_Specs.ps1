$ClusterName = $FALSE
$ClusterName = read-host "Enter Cluster name, or leave blank for local Host"

if(-NOT (Test-Path "C:\Temp\")){
	New-Item -Path "C:\Temp\" -ItemType Directory 
}

if($ClusterName){

	$VMHs = get-clusternode -cluster $ClusterName
	
	$FName_VM = "C:\Temp\" + $ClusterName + "_VM_Stats_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"
	$FName_VHD = "C:\Temp\" + $ClusterName + "_VHD_Stats_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"

	
	foreach($VMH in $VMHs){
		
		foreach($VM in get-vm -computername $VMH){
			
			$VM_Stats = New-Object -TypeName PSObject
			$VM_Stats | Add-Member -MemberType NoteProperty -Name VMHost $VMH
			$VM_Stats | Add-Member -MemberType NoteProperty -Name VMName $VM.Name
			$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_vCPU $VM.ProcessorCount
			$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_RAM (($VM.MemoryAssigned)/(1024 * 1024 * 1024))
			
			$VHDs_Size = 0
			$VHDs_Prov = 0
			
			$VHDs = Invoke-Command -ComputerName $VMH.name -ScriptBlock {(get-vmharddiskdrive $args[0]).Path | Get-VHD} -argumentlist $VM.name

			foreach($VHD in $VHDs){
			
				$VHD_Stats = New-Object -TypeName PSObject
				$VHD_Stats | Add-Member -MemberType NoteProperty -Name VMHost $VMH
				$VHD_Stats | Add-Member -MemberType NoteProperty -Name VMName $VM.Name
				$VHD_Stats | Add-Member -MemberType NoteProperty -Name VHD_Path -Value $VHD.Path
				$VHD_Stats | Add-Member -MemberType NoteProperty -Name VHD_Size -Value ($VHD.filesize/1gb -as [int])
				$VHD_Stats | Add-Member -MemberType NoteProperty -Name VHD_Prov -Value ($VHD.size/1gb -as [int])
				
				$VHDs_Size += ($VHD.filesize/1gb -as [int])
				$VHDs_Prov += ($VHD.size/1gb -as [int])
				
				Export-Csv $FName_VHD -InputObject $VHD_Stats -Append -NoTypeInformation -Force
			}
			
			$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_Size $VHDs_Size
			$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_Prov $VHDs_Prov
			
			Export-Csv $FName_VM -InputObject $VM_Stats -Append -NoTypeInformation -Force
			
		}
	}

}else{
	
	$VMH = hostname
	
	$FName_VM = "C:\Temp\" + $VMH + "_VM_Stats_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"
	$FName_VHD = "C:\Temp\" + $VMH + "_VHD_Stats_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"


	foreach($VM in get-vm){
		
		$VM_Stats = New-Object -TypeName PSObject
		$VM_Stats | Add-Member -MemberType NoteProperty -Name VMName $VM.Name
		$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_vCPU $VM.ProcessorCount
		$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_RAM (($VM.MemoryAssigned)/(1024 * 1024 * 1024))
		
		$VHDs_Size = 0
		$VHDs_Prov = 0
		
		$VHDs = (get-vmharddiskdrive $VM).Path | Get-VHD

		foreach($VHD in $VHDs){
		
			$VHD_Stats = New-Object -TypeName PSObject
			$VHD_Stats | Add-Member -MemberType NoteProperty -Name VMName $VM.Name
			$VHD_Stats | Add-Member -MemberType NoteProperty -Name VHD_Path -Value $VHD.Path
			$VHD_Stats | Add-Member -MemberType NoteProperty -Name VHD_Size -Value ($VHD.filesize/1gb -as [int])
			$VHD_Stats | Add-Member -MemberType NoteProperty -Name VHD_Prov -Value ($VHD.size/1gb -as [int])
			
			$VHDs_Size += ($VHD.filesize/1gb -as [int])
			$VHDs_Prov += ($VHD.size/1gb -as [int])
			
			Export-Csv $FName_VHD -InputObject $VHD_Stats -Append -NoTypeInformation -Force
		}
		
		$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_Size $VHDs_Size
		$VM_Stats | Add-Member -MemberType NoteProperty -Name VM_Prov $VHDs_Prov
		
		Export-Csv $FName_VM -InputObject $VM_Stats -Append -NoTypeInformation -Force
		
	}
}

write-host "$FName_VM"
write-host "$FName_VHD"
