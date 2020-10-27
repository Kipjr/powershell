param (
    [string]$hosts = "localhost" 
)
$hosts = $hosts.split("`n")
$hosts = $hosts.trim()

$data = @()
##Domain
foreach($h in $hosts) {
	##Host
    $memory = (Get-WmiObject win32_physicalmemory -Property Capacity -ComputerName $h -ErrorVariable Err -ErrorAction SilentlyContinue |  measure -Property Capacity -sum | select -ExpandProperty Sum) /1MB
	#write-host($h)
	#write-host($memory)
	#write-host($Err)
	$vms = $null
	$vms = get-vm -computername $h 
	$hostdata = new-object -TypeName PSCustomOBject
	$hostdata | Add-Member -MemberType NoteProperty -name ComputerName -value $($h.split(".")[0])	
	foreach($vm in $vms){

		##VM
		$vmdata = $vm | select-Object -Property ComputerName,Name,State,ProcessorCount,CPUUsage,DynamicMemoryEnabled,MemoryMaximum,MemoryStartup,MemoryMinimum,MemoryAssigned,MemoryDemand,Uptime,Version,Generation,Path
		$vmdata.MemoryAssigned/=1MB
		$vmdata.Uptime = $($vmdata.Uptime).days + [math]::Round($($vmdata.Uptime).Hours/24,2)
		if($vmdata.DynamicMemoryEnabled -eq "True") {
			$vmdata.MemoryStartup = [math]::Round(($vmdata.MemoryStartup/$vmdata.MemoryMaximum)*100)
			$vmdata.MemoryMinimum/=1MB
			$vmdata.MemoryMaximum/=1MB
		}
		else {
			$vmdata.MemoryMinimum = $null
			$vmdata.MemoryMaximum = $null
			$vmdata.MemoryStartup = $null
		}		
		$vmdata.MemoryDemand/=1MB
		$memory -= $vmdata.MemoryAssigned
		$data+=$vmdata
	}
	$hostdata | Add-Member -MemberType NoteProperty -name State -value $($memory-2048)
	$data+=$hostdata
}
format-table -inputobject $data	 -Wrap -AutoSize -Property *
