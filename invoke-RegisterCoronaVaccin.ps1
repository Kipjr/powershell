Param(
  [int]$year=1984,
  [int]$deltaYear=10
)
$result1 = Invoke-WebRequest -UseBasicParsing -Uri "https://user-api.coronatest.nl/vaccinatie/programma/booster/$($year-$deltaYear)/NEE" 
while(($result1.Content |ConvertFrom-Json).Success  -eq $true){
  $result2 = Invoke-WebRequest -UseBasicParsing -Uri "https://user-api.coronatest.nl/vaccinatie/programma/booster/$year/NEE" 
  if(($result2.Content |ConvertFrom-Json).Success  -eq $true) {
    start-process "chrome" -ArgumentList "https://coronatest.nl/ik-wil-me-laten-vaccineren/wat-is-uw-geboortejaar"
    exit 0
  }
  start-sleep 300
}
"Nog even geduld..." | write-host -foregroundcolor cyan
start-sleep 5
exit 1
