#Server Names
$Servers = @("sydsrv01","newsrv01")
#Share Names
$Shares = @("Admin", "AdminV2", "Users$")
#Replication Group Name
$RGName = "CLI"

Foreach($SrcServer in $Servers){
	Foreach($DstServer in $Servers){
    	If ($SrcServer -ne $DstServer){
			Write-Host "Backlog from $SrcServer to $DstServer"
			Foreach($Share in $Shares){
				
				#Build DFSRDiag Command to use Invoke-Expression
				$BLCommand = "DfsrDiag Backlog /Sendingmember:"+$SrcServer+" /ReceivingMember:"+$DstServer+" /rgname:'"+$RGName+"' /rfname:'"+$Share+"'"
				
				#Get Backlog List
				$Backlog = Invoke-Expression -Command $BLCommand
				
				#Count Backlog of Files
				$BackLogFilecount = 0
				foreach ($item in $Backlog)
				{
					if ($item -ilike "*Backlog File count*")
					{
						$BacklogFileCount = [int]$item.split(":")[1].trim()
					}
				}
				
				#Pretty Colours
				if ($BacklogFileCount -eq 0){
					$Color="white"
				}
				elseif ($BacklogFilecount -lt 10){
					$Color="yellow"
				}
				else{
					$Color="red"
				}
				
				#Output Results
				Write-Host "$BacklogFileCount files in backlog $SrcServer->$DstServer for $Share" -fore $Color
		
			}
		}
	}
}


Read-Host "Press Enter to continue"
