Param(
[string]$ClusterName,
[string]$SMTPServer
)

#Check installed modules
if(-NOT (Get-WindowsFeature RSAT-Clustering-PowerShell).installed){
	Add-WindowsFeature RSAT-Clustering-PowerShell
}

if(-NOT (Get-WindowsFeature Hyper-V-PowerShell).Installed){
	Install-WindowsFeature Hyper-V-PowerShell
}

#Objects for output
$FailedReplicas = @()
$StatusReplicas = @()

#Get VMs with critical/failed replicas
foreach ($VMH in (Get-ClusterNode -Cluster $ClusterName)){

	$FailedReplicas += Get-VMReplication -computername $VMH | Where{($_.Health -EQ 'Critical') -AND -NOT (($_.ReplicationState -EQ "Resynchronizing") -OR ($_.ReplicationState -EQ "Replicating")  -OR ($_.ReplicationState -EQ "WaitingForStartResynchronize"))}

}

#Output results to screen
$FailedReplicas | ft PrimaryServer, Name, ReplicationHealth, ReplicationState, LastReplicationTime

#Resume Replication for VMs
ForEach ($VM in $FailedReplicas)
{
	Resume-VMReplication -ComputerName "$($VM.Primaryserver)" -VMName "$($VM.Name)" -Resynchronize
}

SLEEP 5

#Check status after resumed replication
foreach ($VMH in (Get-ClusterNode -Cluster $ClusterName)){

	$StatusReplicas += Get-VMReplication -computername $VMH | Where{($_.Health -EQ 'Critical')} | Select PrimaryServer, Name, ReplicationHealth, ReplicationState, LastReplicationTime

}

#Output results to screen
$StatusReplicas | ft PrimaryServer, Name, ReplicationHealth, ReplicationState, LastReplicationTime

#format email with details to send to support mailbox
$ClusterDetails = Get-cluster -name $ClusterName
$Sender = "$($ClusterDetails.Name)@$($ClusterDetails.Domain)"
$Body = "Errors Detected with Replication @ $(Get-Date -format 'dd/MM/yyyy HH:mm')" + ($StatusReplicas|Out-String)

Send-MailMessage -SmtpServer $SMTPServer -From $Sender -To "support@msp.net.au" -Subject "$ClusterName - Replication Errors" -Body $Body

