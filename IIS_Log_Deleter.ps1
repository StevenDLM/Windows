# Delete all Files in C:\inetpub\logs\LogFiles on webserver older than 15 day(s)
$Path = "C:\inetpub\logs\LogFiles"
$Daysback = "-15"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
Get-ChildItem $Path -Recurse | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
