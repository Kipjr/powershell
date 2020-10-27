param (
    [string]$hostname = "localhost" 
)
Get-BitlockerVolume -MountPoint "C:">null
$rec = $BLV.KeyProtector[1].RecoveryPassword
$id = $BLV.KeyProtector[1].KeyProtectorId
$string = "$hostname;$rec;$id"
"Hostname;RecoveryPassword;KeyProtectorId" > c:/temp/$hostname.csv
$string >> c:/temp/$hostname.csv
