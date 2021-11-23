Param([string]$ReportPath = "C:\Temp")

$ValidMenu = $FALSE
cls

#Display Menu
do{
    $MenuNum = read-host "
    1) Backups
    2) Replicas

    Select type of job to Export and press Enter"

    switch ($MenuNum){
        1{$Type = "Backup";$ValidMenu=$TRUE;break}
        2{$Type = "Replica";$ValidMenu=$TRUE;break}
        #3{$Type = "SimpleBackupCopyPolicy";$ValidMenu=$TRUE;break}
        default{$ValidMenu=$FALSE}
    }
}until($ValidMenu)

#Set Report Path
$TimeStamp = (Get-Date -format yyyyMMdd-HHmm)
$File = "$ReportPath\Veeam_$($Type)_$($TimeStamp).csv"

write-host "Reading Veeam Jobs now..."


$i=0
$VeeamJobs = Get-VBRJob -WarningAction SilentlyContinue | ?{$_.JobType -eq "$Type"}

#Reads all Veeam jobs and collates them into nice CSV report to identify Frequency, Location, Space Used, Last Results and Retention
$VeeamJobs | %{


	$job = $_
    $JobName = $_.Name

	$percent = [math]::Round($i / $VeeamJobs.count*100 , 2)
	Write-Progress -Activity "Exporting Data..." -status "$percent% | Reading Job: $JobName" -percentComplete $percent
	$i++
    
    $Backup = Get-VBRBackup -Name $JobName
	$Schedules = $_.ScheduleOptions
	
	if ($Schedules.OptionsDaily.Enabled){
	$ScheduleType = "Daily"
		$ScheduleFreq = $Schedules.OptionsDaily.DaysSrv
		$ScheduleTime = $Schedules.OptionsDaily.TimeLocal.TimeOfDay.tostring()
	}
	
	if ($Schedules.OptionsMonthly.Enabled){
		$ScheduleType = "Monthly"
		$FreqNum = $Schedules.OptionsMonthly.DayNumberInMonth
		$FreqDay = $Schedules.OptionsMonthly.DayofWeek
		$FreqMonth = $Schedules.OptionsMonthly.Months
		$ScheduleFreq = "$FreqNum $FreqDay of $FreqMonth"
		$ScheduleTime = $Schedules.OptionsMonthly.TimeLocal.TimeOfDay.tostring()
	}
	
	if ($Schedules.OptionsPeriodically.Enabled){
		$ScheduleType = "Periodically"
		$ScheduleFreq = "Every $($Schedules.OptionsPeriodically.FullPeriod) $($Schedules.OptionsPeriodically.Unit)"
		$ScheduleTime = $Schedules.OptionsPeriodically.Schedule
	}
	
	if ($Schedules.OptionsContinuous.Enabled){
		$ScheduleType = "Continuously"
		$ScheduleList = $ScheduleOptions.OptionsContinuously
		$ScheduleTime = "Continuous"
	}

	$lastsession = $job.FindLastSession()
    $Session = $job.FindLastSession()
    
    foreach($tasksession in $lastsession.GetTaskSessions()) {
        $PointsOnDisk = (get-vbrbackup -Name $job.Name | Get-VBRRestorePoint -Name $tasksession.Name | Measure-Object).Count 
        $BackupTotalSize = [math]::round($Session.Info.Progress.TotalUsedSize/1Gb,2)
        $BackupSize = [math]::round($Session.Info.BackedUpSize/1Gb,2)
        try{$RepositoryPath = $Backup.Info.DirPath.ToString()}
        catch{$RepositoryPath = ""}
        $LastBackupStart = $Session.CreationTime
        $LastResult = $job.GetLastResult()
        $Target = $job.GetTargetRepository().Name
        $info = $job.GetOptions()
        $pointtokeep = $job.Options.GenerationPolicy.SimpleRetentionRestorePoints
        $GFSmonthly= $job.Options.generationpolicy.GFSMonthlyBackups
        $GFSYearlyBackups = $job.Options.generationpolicy.GFSYearlyBackups
        $RetentionPolicyType = $job.Options.generationpolicy.RetentionPolicyType
        $Retention = $info.options.rootnode.retaincycles

    }
	$_ | Get-VBRJobObject | ?{$_.Object.Type -eq "VM"} | Select @{ L="Job"; E={$JobName}}, Name, @{ L="Schedule Type"; E={$ScheduleType}}, @{ L="Frequency"; E={$ScheduleFreq}},@{ L="Time"; E={$ScheduleTime}},@{ L="VM Size"; E={$_.ApproxSizeString}}, @{ L="LastResult"; E={$LastResult}}, @{ L="LastBackupStart"; E={$LastBackupStart}}, @{ L="LastBackupSize"; E={$BackupSize}}, @{ L="LastBackupTotalSize"; E={$BackupTotalSize}}, @{ L="Repository"; E={$Target}}, @{ L="PointsOnDisk"; E={$PointsOnDisk}}, @{ L="Retention"; E={$Retention}}  | Sort -Property Job, Name 
} | Export-csv $File -NoTypeInformation

write-host "Exported Veeam Jobs to: $($File)"
