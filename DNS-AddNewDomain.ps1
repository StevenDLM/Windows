param(
	$NS_1 = "ns1.a.net.au.",
	$NS_2 = "ns2.a.net.au.",
	$NS_Master = '1.2.1.2'
)

#Prompt User for new Domain Name
$Domain = read-host "Enter the domain name you wish to add"

#Create DNS Zone
add-dnsserverprimaryzone -name $Domain -zonefile "$($Domain).dns"

#Construct DNS SOA as Object Part 1
$OldSOA = Get-DnsServerResourceRecord -ZoneName $Domain -RRType "SOA"
$NewSOA = $OldSOA.Clone()
$NewSOA.RecordData.ExpireLimit = [System.TimeSpan]::FromDays(14)
$NewSOA.RecordData.PrimaryServer = $NS_1
$NewSOA.RecordData.RefreshInterval = [System.TimeSpan]::FromHours(1)
$NewSOA.RecordData.ResponsiblePerson = "hostmaster.$($Domain)"

#Set DNS Object Part 1
Set-DnsServerResourceRecord -NewInputObject $NewSOA -OldInputObject $OldSOA -ZoneName $Domain -PassThru

#Construct DNS SOA as Object Part 2
$OldNS = Get-DnsServerResourceRecord -ZoneName $Domain -RRType "NS"
$NewNS = $OldNS.Clone()
$NewNS.RecordData.NameServer = $NS_1

#Set DNS Object Part 2
Set-DnsServerResourceRecord -NewInputObject $NewNS -OldInputObject $OldNS -ZoneName $Domain -PassThru

#Add 2nd NS Server
Add-DnsServerResourceRecord -ZoneName $Domain -NS -Name "@" -NameServer $NS_2

#Completed Output
write-host "DNS Zone added" -ForegroundColor Green

#Generates cmdlet for secondary NS to add Domain
write-host "Copy and paste below into powershell prompt on secondary DNS Server:"
write-host "add-dnsserversecondaryzone -Name '$Domain' -ZoneFile '$($Domain).dns' -MasterServers $NS_Master" -BackgroundColor Black
