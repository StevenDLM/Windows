Params(
[string]$FilePath = "C:\Temp\"
)

#Build File Name, VM List, esets progress variable
$Hostname = hostname
$FName_VM = $FilePath + $Hostname + "_Repl_Stats_" + (Get-Date -format yyyyMMdd-HHmm) + ".csv"
$progress = 0
$VMs = (get-vm | ?{$_.PowerState -eq "PoweredOn"})

foreach ($VM in $VMs)
{
  #Progress Output
  $progress++
	$percent = [math]::Round($progress/($VMs.count)*100 , 2)
	Write-Progress -Activity "Collating for Replication Details" -status "${percent}% | Checking $($VM.Name)" -percentComplete $percent
	
  #Bool to check if replication event found
  $evtFound = $FALSE
  
  #Limits number of Events, else search may never end
	$evtLimit = 10
	
  #Retrieves VMEvents
  $VMEvents = $VM | get-vievent -maxsamples $evtLimit
	
  #Foreach Event
	foreach($VMEvent in $VMEvents)
	{
    #Check for event containing replication info
		if ($VMEvent.EventTypeId -match 'hbr|rpo')
		{
      #Store relevant details of event
			$Msg = $VMEvents[$i].FullFormattedMessage
			$TimeStamp = $VMEvents[$i].CreatedTime
			$Size = [math]::Round($VMEvents[$i].Arguments.Value/1MB, 2)
      
      #Confirm Event found and Break forloop
			$evtFound = $TRUE
      break
		}
	}
	
  #If found
	if (-NOT $evtFound)
	{
    #Set event details as below
		$Msg = "$($VM.Name) Replication Events not found"
		$TimeStamp = 0
		$Size = 0
	}
	
  #Bool to search for VM Files in Datastore
	$volFound = $FALSE
	foreach($i in 1..4)
	{
	
		if ($Searching -AND (dir -path "vmstore:\VOL0$i" | ?{$_.Name -eq $VM.Name}))
		{
			#Set Datastore details
      $ReplStore = "VOL0$i"
      
      #Confirm VolFound and break forloop
			$volFound = $TRUE
      break
		}
	
	}
	
  #If Vol not found report details
	if (-NOT $volFound)
	{
		$ReplStore = "$($VM.Name) Replication Datastore not found"
	}

  #Create and populate objects
	$Repl_Stats = New-Object -TypeName PSObject
	$Repl_Stats | Add-Member -MemberType NoteProperty -Name VMName $VM.Name
	$Repl_Stats | Add-Member -MemberType NoteProperty -Name Power $VM.PowerState
	$Repl_Stats | Add-Member -MemberType NoteProperty -Name Status $Msg
	$Repl_Stats | Add-Member -MemberType NoteProperty -Name TimeStamp $TimeStamp
	$Repl_Stats | Add-Member -MemberType NoteProperty -Name MB $Size
	$Repl_Stats | Add-Member -MemberType NoteProperty -Name "Repl Store" $ReplStore
	
  #Append object details to CSV
	Export-Csv $FName_VM -InputObject $Repl_Stats -Append -NoTypeInformation -Force
	
}
