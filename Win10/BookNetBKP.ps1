write-host "Getting Ready..."
$fss = "BNETNX5"
$backdir = "C:\Users\Username\BookNetBKP"
$workdir = "c:\BookNetNX5"
$ddir = "c:\BookNetNX5\Data"
$DayName = ((get-date).dayofweek).tostring().substring(0,3)
$FileName = "$fss-$DayName.zip"
$LogName = "$fss-$DayName.log"

write-host "Checking for path/files..."
if (test-path $backdir){
    if ((test-path "$backdir\$FileName")){
        remove-item "$backdir\$FileName"
    }
}else{
    mkdir $backdir
}
start-transcript "$backdir\$LogName"

write-host "Stopping Micro Focus Fileshare Service..."
&"$workdir\ugclose.exe" $fss

write-host "Compressing data files..."
write-host "$ddir -> $backdir\$FileName"
compress-archive "$ddir" "$backdir\$FileName" -compressionlevel fastest
 
write-host "Restarting Micro Focus Fileshare Service..."
net start "Micro Focus Fileshare Service"

SLEEP 30
stop-transcript

$Server = "smtp.msp.net.au"
$sender = "cli@cli.com.au"
$recipient = "support@msp.net.au"

$hostname = hostname

Send-MailMessage -SmtpServer "$Server" -From "$sender" -To "$recipient" -Subject "TBD - Backups [1195-330517]" -Body "Script Completed by $hostname" -attachments "$backdir\$LogName"
