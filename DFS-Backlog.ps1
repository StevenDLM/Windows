
$Servers = @("sydsrv01","newsrv01")
$Shares = @("Admin", "AdminV2", "Users$")
$RGName = "CLI"

Foreach($SrcServer in $Servers){
	Foreach($DstServer in $Servers){
    	If ($SrcServer -ne $DstServer){
			Write-Host "Backlog from $SrcServer to $DstServer"
			Foreach($Share in $Shares){
				
				$BLCommand = "DfsrDiag Backlog /Sendingmember:"+$SrcServer+" /ReceivingMember:"+$DstServer+" /rgname:'"+$RGName+"' /rfname:'"+$Share+"'"
				$Backlog = Invoke-Expression -Command $BLCommand
				$BackLogFilecount = 0
				foreach ($item in $Backlog)
				{
					if ($item -ilike "*Backlog File count*")
					{
						$BacklogFileCount = [int]$item.split(":")[1].trim()
					}
				}
				
				if ($BacklogFileCount -eq 0){
					$Color="white"
				}
				elseif ($BacklogFilecount -lt 10){
					$Color="yellow"
				}
				else{
					$Color="red"
				}
				Write-Host "$BacklogFileCount files in backlog $SrcServer->$DstServer for $Share" -fore $Color
		
			}
		}
	}
}


Read-Host "Press Enter to continue"