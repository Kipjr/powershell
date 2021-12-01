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
