param (
    [bool]$limit = $true, #limit 500 rows
    [string]$action = $null,
    [string]$protocol = $null,
    [bool]$resolve = $false, #resolve DNS
    [string]$hostname = "localhost" 

)

$windir = $env:windir
$computername = $env:COMPUTERNAME 
if($hostname -ne "localhost"){
    $computername=$hostname
    $windir="\\$($hostname)\c$\windows"
}

$logs=get-item -Path $windir\system32\LogFiles\Firewall\*.log
if(($logs).length -eq 0) {write-host("No logs found");exit}

$vars=@()
foreach($i in $logs) {
    $name = ($i.Name).split(".")[1]
    $fullname=$i.FullName
    $vars+="log_$($name)"
    Set-Variable -name "log_$($name)" -Value $(Get-Content -Path $fullname)
}


##Fields: date time action protocol src-ip dst-ip src-port dst-port size tcpflags tcpsyn tcpack tcpwin icmptype icmpcode info path
#2020-10-26 10:00:00 ALLOW ICMP 1.2.3.4 5.6.7.8 - - 0 - - - - 8 0 - RECEIVE

$logdata=@()
foreach ($v in $vars) { #foreach logsfile/var
    $log = Get-Variable $v -ValueOnly #gimme content of var
    $log=$log.split("`n") #newline
    if($log.Length -le 7) {continue} #dont want empty logs
    $log=$log[5..($log.length - 1)] #skip first 4 rows
    If($limit) {
       $log=$log[($log.length - 500)..($log.length - 1)] #only 500 rows
    }
    
    foreach($r in $log) { #foreach row
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
            $d[4] = if($d4.IsFaulted) {$d[4]} else {$d4.result.hostname} 
            $d[5] = if($d5.IsFaulted) {$d[5]} else {$d5.result.hostname} 
        }
        $obj | Add-Member -MemberType NoteProperty -Name src-ip -Value  $(If ($d[4] -ne "-") {$d[4]} Else {$null})
        $obj | Add-Member -MemberType NoteProperty -Name dst-ip -Value  $(If ($d[5] -ne "-") {$d[5]} Else {$null})
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
    }
 }

 #Format-Table  -AutoSize $true -Wrap -Property *
 $logdata | Out-GridView
