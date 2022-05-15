$putty = Get-ItemProperty "HKCU:\SOFTWARE\SimonTatham\PuTTY\Sessions\*"
$ts = get-date -format "yyyy-MM-ddTHH-mm-ss"
$WinTermSettingsItem = get-item "$env:localappdata\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json"
$WinTermSettingsItem  | Copy-Item -Destination "$($WinTermSettingsItem.FullName).$ts.backup"
$WinTermSettings = $WinTermSettingsItem | Get-Content | ConvertFrom-Json

foreach($p in $putty.where({$_.pschildname -ne "Default%20Settings"}) ) {
    $name = $p.PSChildName
    
    $options = " -o "
    $destination = " $($p.HostName)"
    $port = " -p $($p.PortNumber)"
    $log_file = if($p.LogType -ne 0) {" -E `"$($p.LogFileName.replace('&H',$name))`""} 
    $login_name = if($p.UserName -ne "") {" -l $($p.UserName)"} else {" -l "+$(read-host -prompt "Username for $($p.hostname):$($p.PortNumber)")}
    $identity_file = if($p.PublicKeyFile -ne "") {" -i `"$($p.PublicKeyFile)`""}
    $options += if($p.TCPKeepAlives -ne 0){"TCPKeepAlive"}
    $command = if($p.RemoteCommand -ne "") {" $($p.RemoteCommand)"} 
    $options=if($options.length -le 4) {$null}    
    $commandline="ssh"+$log_file+$identity_file+$login_name+$options+$port+$destination+$command
    
    if(($index = $WinTermSettings.profiles.list.name.indexof("SSH: $name")) -ne -1) {
        #existing
        $WinTermSettings.profiles.list[$index].commandline=$commandline
        
    } else {
        #new
        $SSHObject='{"name":"","guid":"","hidden": false,"icon":"ms-appx:///ProfileIcons/{550ce7b8-d500-50ad-8a1a-c400c3262db3}.scale-200.png","StartingDirectory":null,"Source":null,"commandline":""}' | convertfrom-json
        $SSHObject.guid = "{$(new-guid)}"
        $SSHObject.hidden= $false
        $SSHObject.name = "SSH: $name"
        $SSHObject.commandline = $commandline
        
        $WinTermSettings.profiles.list+=($SSHObject)
    }
}

$WinTermSettings  | convertto-json -Depth 5 | Set-Content -path $($WinTermSettingsItem.FullName) | ConvertFrom-Json
