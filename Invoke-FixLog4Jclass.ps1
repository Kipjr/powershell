Param(
    [switch]$fix
)
<#
$computernames = ('[
  "1",
  "2"
]' | convertfrom-json) |% { [pscustomobject]@{Name="$_"} }
#>
if(-not($computernames)){
	$computerNames = @(get-adcomputer -Filter { OperatingSystem -Like '*Windows Server*' } -Properties * | Select name )
} 
if($fix.IsPresent -eq $true){
    "This will install 7zip if not present. Required to remove from inside .jar files" | write-host
    sleep 1
    pause
}    
 $logfile = "./Log4j.log"
$ignoreDrives = @("A", "B" ) # A and B not relevant, D is temp drive of Azure VMs
$keyword = "*log4j-*.jar"

Start-Transcript -Path $logfile
$scriptblock = {
    Param ( [object]$computer,[String] $keyword, [String[]] $ignoreDrives )
    #$computer.name # Show computername
    if ((Test-Connection -computername $computer.name -Quiet) -eq $true) {
        Invoke-Command -ComputerName $computer.name -ScriptBlock {
            $drives = Get-PSDrive -PSProvider FileSystem
            foreach ($drive in $drives) {
                if ($drive.Name -notin $using:ignoreDrives) {
                    $items = Get-ChildItem -Path $drive.Root -Filter $using:keyword -ErrorAction SilentlyContinue -File -Recurse
                    foreach ($item in $items) {
                        "Found: $($env:COMPUTERNAME);$($item.name);$($item.FullName)" | write-host  # Show all files found with full drive and path
                        if($item.Fullname | Select-String 'log4j-core-2.*'){
                            if($fix.IsPresent -eq $true){
                                if(-not(test-path -path 'C:\Program Files\7-Zip\7z.exe')) {
                                    curl   -o 'c:\temp\7zip.exe' 'https://d2.7-zip.org/a/7z2106-x64.exe' --ssl-no-revoke
                                    c:\temp\7zip.exe /S 
                                    start-sleep 20
                                }
                                "Trying to remove: $($item.FullName)" | write-host  # Show all files found with full drive and path
                                $result = & "C:\Program Files\7-Zip\7z.exe" l "$($item.FullName)"  | select-string "org\\apache\\logging\\log4j\\core\\lookup\\JndiLookup.class"
                                if($result) {& "C:\Program Files\7-Zip\7z.exe" d $($item.FullName) "org\apache\logging\log4j\core\lookup\JndiLookup.class" }
                            } else {
                                "Please manually remove class 'JndiLookup.class' from: $($item.FullName)" | write-host
                            }
                            
                        }
                    }
                }
            }
        }
    }
    else{
     "$($computer.name);Offline"| write-host
     }
}
foreach($computer in $computernames){
    Start-Job $scriptblock -ArgumentList ($computer,$keyword,$ignoreDrives)
}
Get-job | Wait-Job | Receive-Job | write-host
get-job | remove-job

<# Output
Id     Name            PSJobTypeName   State         HasMoreData     Location             Command
--     ----            -------------   -----         -----------     --------             -------
1      Job1            BackgroundJob   Running       True            localhost            ...
3      Job3            BackgroundJob   Running       True            localhost            ...
5      Job5            BackgroundJob   Running       True            localhost            ...
7      Job7            BackgroundJob   Running       True            localhost            ...
9      Job9            BackgroundJob   Running       True            localhost            ...
11     Job11           BackgroundJob   Running       True            localhost            ...
13     Job13           BackgroundJob   Running       True            localhost            ...
15     Job15           BackgroundJob   Running       True            localhost            ...
17     Job17           BackgroundJob   Running       True            localhost            ...
19     Job19           BackgroundJob   Running       True            localhost            ...
21     Job21           BackgroundJob   Running       True            localhost            ...

Found: SERVERNAME1;C:\PathToFile\log4j-1.2-api-2.15.0.jar
Found: SERVERNAME1;C:\PathToFile\log4j-api-2.15.0.jar
Found: SERVERNAME1;C:\PathToFile\log4j-core-2.15.0.jar

Trying to remove: C:\PathToFile\log4j-core-2.15.0.jar
7-Zip 21.06 (x64) : Copyright (c) 1999-2021 Igor Pavlov : 2021-11-24
Open archive: C:\PathToFile\log4j-core-2.15.0.jar
--
Path = C:\PathToFile\log4j-core-2.15.0.jar
Type = zip
Physical Size = 1789769
Updating archive: C:\PathToFile\log4j-core-2.15.0.jar
Delete data from archive: 1 file, 2937 bytes (3 KiB)
Keep old data in archive: 77 folders, 1141 files, 3971678 bytes (3879 KiB)
Add new data to archive: 0 files, 0 bytes
Files read from disk: 0
Archive size: 1788198 bytes (1747 KiB)
Everything is Ok

Found: SERVERNAME1;C:\PathToFile\log4j-slf4j-impl-2.15.0.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2-api-2.8.1.jar
Found: SERVERNAME1;C:\PathToFile\log4j-api-2.8.1.jar
Found: SERVERNAME1;C:\PathToFile\log4j-core-2.8.1.jar

Trying to remove: C:\PathToFile\log4j-core-2.8.1.jar
7-Zip 21.06 (x64) : Copyright (c) 1999-2021 Igor Pavlov : 2021-11-24
Open archive: C:\PathToFile\log4j-core-2.8.1.jar
--
Path = C:\PathToFile\log4j-core-2.8.1.jar
Type = zip
Physical Size = 1402925
Updating archive: C:\PathToFile\log4j-core-2.8.1.jar
Delete data from archive: 1 file, 3022 bytes (3 KiB)
Keep old data in archive: 66 folders, 929 files, 3060061 bytes (2989 KiB)
Add new data to archive: 0 files, 0 bytes
Files read from disk: 0
Archive size: 1401325 bytes (1369 KiB)
Everything is Ok

Found: SERVERNAME1;C:\PathToFile\log4j-slf4j-impl-2.8.1.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.12.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.17.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.12.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.12-json-layout.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.12.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.12.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.17.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.12-json-layout.jar
Found: SERVERNAME1;C:\PathToFile\log4j-1.2.12.jar
Found: SERVERNAME1;C:\PathToFile\log4j-over-slf4j-1.7.25.jar
#>
