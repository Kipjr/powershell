Param(
  [int]$year=1980,
  [int]$deltaYear=10
)
$result1 = Invoke-WebRequest -UseBasicParsing -Uri "https://user-api.coronatest.nl/vaccinatie/programma/booster/$($year-$deltaYear)/NEE" 
while(($result1.Content |ConvertFrom-Json).Success  -eq $true){
  $result2 = Invoke-WebRequest -UseBasicParsing -Uri "https://user-api.coronatest.nl/vaccinatie/programma/booster/$year/NEE" 
  if(($result2.Content |ConvertFrom-Json).Success  -eq $true) {
	[console]::Beep(400,300); [console]::Beep(450,300);[console]::Beep(500,300);
    start-process "chrome" -ArgumentList "https://coronatest.nl/ik-wil-me-laten-vaccineren/wat-is-uw-geboortejaar"
    exit 0
  }
  start-sleep 300
}
[console]::Beep(300,200);[console]::Beep(200,300);
exit 

<# Save as task.xml and import it in task scheduler
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2021-12-01T08:42:49.6229829</Date>
    <Author>Kipjr</Author>
    <URI>\CoronaVaccineRegistration</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <Delay>PT15M</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId></UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT8H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-WindowStyle Minimized -file "C:\temp\Scripts\Powershell\invoke-RegisterCoronaVaccin.ps1"</Arguments>
      <WorkingDirectory>C:\temp\Scripts\Powershell\</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
#>
