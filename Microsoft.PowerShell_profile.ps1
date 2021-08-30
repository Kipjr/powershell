#Function GetKeyPress([string]$regexPattern='[0-9]', [string]$message=$null, [int]$timeOutSeconds=0){
if($myinvocation.line -eq $null) {

    Function GetKeyPress( [string]$message=$null, [int]$timeOutSeconds=0){
        $key = $null
        $Host.UI.RawUI.FlushInputBuffer() 
        if (![string]::IsNullOrEmpty($message)){
            Write-Host -NoNewLine $message
        }
        $counter = $timeOutSeconds * 1000 / 250
        while($key -eq $null -and ($timeOutSeconds -eq 0 -or $counter-- -gt 0)){
            if (($timeOutSeconds -eq 0) -or $Host.UI.RawUI.KeyAvailable){                       
                $key_ = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
                #if ($key_.KeyDown -and $key_.Character -match $regexPattern){
                if ($key_.KeyDown){
                    $key = $key_                    
                }
            } else {
                Write-Host -NoNewline "."	
                Start-Sleep -m 250  # Milliseconds
            }
        }                       
        if (-not ($key -eq $null)){
            Write-Host -NoNewLine "$($key.Character)" 
        }
        if (![string]::IsNullOrEmpty($message)){
            Write-Host "" # newline
        }       
        #return $(if ($key -eq $null) {$null} else {$key.Character})
        return $(if ($key -eq $null) {$null} else {([int]$($key.Character).tostring())})
    }
    $locations=@()
    $locations+=[pscustomobject]@{id= '0';loc='C:\Temp\'}
    $locations+=[pscustomobject]@{id= '1';loc="$env:userprofile" }
    $locations+=[pscustomobject]@{id= '2';loc='G:\'}
    $locations | ft;

    $key = GetKeyPress "Choose location:" 5

    if ($key -eq $null){
        set-location -path $($locations[0].loc)
    } else {
        set-location -path $($locations[$key].loc)
    }
    clear-host
}
