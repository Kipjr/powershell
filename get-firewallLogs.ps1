param (
    [int]$limit = 500, #limit 500 rows
    [string]$action = $null,
    [string]$protocol = $null,
    [bool]$resolve = $false, #resolve DNS
    $hostname = "localhost" 
)
$debug=$true


#create object from input hostname
switch($hostname.gettype().Name){
    "Object[]" { write-host("Invalid input"); exit}
    "String" {}
    Default { write-host("Invalid input"); exit}
}


if($hostname[0] -eq "localhost"){}
$windir = $env:windir
$computername = $env:COMPUTERNAME 
if($hostname -ne "localhost"){
    $computername=$hostname
    $windir="\\$($hostname)\c$\windows"
}
if($debug){write-host("Windir: $windir") -ForegroundColor Red}

invoke-command -computername $hostname -scriptblock {
        $regkey = $(test-path -path HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging -ErrorAction SilentlyContinue -ErrorVariable e)
        $regkey64 = $(test-path -path HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging -ErrorAction SilentlyContinue -ErrorVariable e)
        $dir = $(test-path -path "C:\Windows\System32\LogFiles\Firewall"  -ErrorAction SilentlyContinue -ErrorVariable e)
}
if($debug){write-host("Regkey: $regkey $regkey64") -ForegroundColor Red}
if(($regkey -eq $false) -or ($regkey64 -eq $false))  {
    write-host("$($hostname):No regkey(32 or 64bit) found");exit
}
if($dir -eq $false) {
    write-host("$($hostname):No log directory found");exit
}



$logs=get-item -Path $windir\system32\LogFiles\Firewall\*.log
if(($logs).length -eq 0) {
    write-host("$($hostname):No logs found");exit
}
if($debug){write-host("Logs: $logs") -ForegroundColor Red}
$vars=@()
foreach($i in $logs) {
    if($debug){write-host("i: $i") -ForegroundColor Red}
    $name = ($i.Name).split(".")[0]
    $fullname=$i.FullName
    $vars+="log_$($name)"
    Set-Variable -name "log_$($name)" -Value $(Get-Content -Path $fullname)
}

if($debug){write-host("Vars: $vars") -ForegroundColor Red}

##Fields: date time action protocol src-ip dst-ip src-port dst-port size tcpflags tcpsyn tcpack tcpwin icmptype icmpcode info path
#2020-10-26 16:52:09 ALLOW ICMP 10.1.2.40 10.1.2.30 - - 0 - - - - 8 0 - RECEIVE
write-host("Start of script: $(get-date)")
$logdata=@()

$i=0
foreach ($v in $vars) { #foreach logsfile/var
    Write-Progress -Activity "Parsing logs" -Id 0 -status "Progress ($i):" -PercentComplete (($i/$vars.length)*100)
    if($debug){write-host("V: $v") -ForegroundColor Red}
    #if($debug){write-host("i: $i") -ForegroundColor Green}
    $log = Get-Variable $v -ValueOnly #gimme content of var
    $log=$log.split("`n") #newline
    if($log.Length -le 7) {continue} #dont want empty logs

    $j=1
    
    

    $log=$log[5..($log.length - 1)] #skip first 4 rows
    $log=$log[($log.length - $limit)..($log.length - 1)] #only 500 rows (or more)
    
    foreach($r in $log) { #foreach row
        Write-Progress -Activity "Parsing rows" -Id 1 -ParentId 0 -status "Progress ($j):" -PercentComplete (($j/$log.length)*100)
        #if($debug){write-host("j: $j") -ForegroundColor Green}
        $d=$r.split(" ")
        If ($action) {
            if ($d[2] -ne $action) {continue}
        } 
        If ($protocol) {
            if ($d[3] -ne $protocol) {continue}
        } 
        $obj = New-Object -TypeName psobject
        $obj | Add-Member -MemberType NoteProperty -Name date -Value  $(If ($d[0] -ne "-") {$d[0]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name time -Value  $(If ($d[1] -ne "-") {$d[1]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name action -Value  $(If ($d[2] -ne "-") {$d[2]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name protocol -Value  $(If ($d[3] -ne "-") {$d[3]} Else {$null})
        if($resolve){
            $d4 = [System.Net.Dns]::GetHostEntryAsync($d[4])
            $d5 = [System.Net.Dns]::GetHostEntryAsync($d[5])
            $fqdn_src = if($d4.IsFaulted) {$null} else {$d4.result.hostname} 
            $fqdn_dst = if($d5.IsFaulted) {$null} else {$d5.result.hostname} 
        } else {
            $fqdn_src = $null
            $fqdn_dst = $null
        }
        $obj | Add-Member -MemberType NoteProperty -Name src-ip -Value  $(If ($d[4] -ne "-") {$d[4]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name src-fqdn -Value $fqdn_src
        $obj | Add-Member -MemberType NoteProperty -Name dst-ip -Value  $(If ($d[5] -ne "-") {$d[5]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name dst-fqdn -Value $fqdn_dst
        $obj | Add-Member -MemberType NoteProperty -Name src-port -Value  $(If ($d[6] -ne "-") {$d[6]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name dst-port -Value  $(If ($d[7] -ne "-") {$d[7]} Else {$null})
        if($all) {
            $obj | Add-Member -MemberType NoteProperty -Name size -Value  $(If ($d[8] -ne "-") {$d[8]} Else {$null})
            $obj | Add-Member -MemberType NoteProperty -Name tcpflags -Value  $(If ($d[9] -ne "-") {$d[9]} Else {$null})
            $obj | Add-Member -MemberType NoteProperty -Name tcpsyn -Value  $(If ($d[10] -ne "-") {$d[10]} Else {$null})
            $obj | Add-Member -MemberType NoteProperty -Name tcpack -Value  $(If ($d[11] -ne "-") {$d[11]} Else {$null})
            $obj | Add-Member -MemberType NoteProperty -Name tcpwin -Value  $(If ($d[12] -ne "-") {$d[12]} Else {$null})
            $obj | Add-Member -MemberType NoteProperty -Name icmptype -Value  $(If ($d[13] -ne "-") {$d[13]} Else {$null})
            $obj | Add-Member -MemberType NoteProperty -Name icmpcode -Value  $(If ($d[14] -ne "-") {$d[14]} Else {$null})
        }
        $obj | Add-Member -MemberType NoteProperty -Name info -Value  $(If ($d[15] -ne "-") {$d[15]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name path -Value  $(If ($d[16] -ne "-") {$d[16]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name logfile -Value  $v
        $obj | Add-Member -MemberType NoteProperty -Name host -Value  $computername

        $logdata+=$obj
        $j++
    }
    $i++
 }

 #Format-Table  -AutoSize $true -Wrap -Property *
 $logdata | Out-GridView
