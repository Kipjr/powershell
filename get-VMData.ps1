param (
    [string]$hosts = "localhost" 
)
$hosts = $hosts.split("`n")
$hosts = $hosts.trim()

$rebootdays = 31
$hvram = 4096
write-host("Start of script: $(get-date)")
$data = @()
##Domain
foreach($h in $hosts) {
	##Host
	$diskIO =  [math]::Round(((Get-WmiObject -Class WIn32_perfformattedData_perfdisk_logicaldisk -Property DiskBytesPersec -ComputerName $h -ErrorVariable Err -ErrorAction SilentlyContinue )[0] | select -expandproperty DiskBytesPersec) /1MB,1)
    $memory = (Get-WmiObject win32_physicalmemory -Property Capacity -ComputerName $h -ErrorVariable Err -ErrorAction SilentlyContinue |  measure -Property Capacity -sum | select -ExpandProperty Sum) /1MB
	#write-host($h)
	#write-host($memory)
	#write-host($Err)
	$vms = $null
	$vms = get-vm -computername $h 
	$spacer= New-Object -TypeName PSCustomObject;$data+=$spacer;	
	foreach($vm in $vms){

		##VM
		$vmdata = $vm | select-Object -Property ComputerName,@{n="RAM"; e={$null}},@{n="I/O (MB/s)"; e={$null}}, Name,State,@{n="Status"; e={""}},ProcessorCount,CPUUsage,DynamicMemoryEnabled,MemoryMaximum,MemoryStartup,MemoryMinimum,MemoryAssigned,MemoryDemand,Uptime,Version,Generation,Path
		$vmdata.MemoryAssigned/=1MB
		$status = ""
		$vmdata.Uptime = $($vmdata.Uptime).days + [math]::Round($($vmdata.Uptime).Hours/24,2)
		if($vmdata.Uptime -gt $rebootdays) {$status+="Reboot suggested, "}
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

		if($vmdata.MemoryDemand -gt $vmdata.MemoryAssigned) {$status+="Increase RAM, "}
		$vmdata.Status = $status
		$memory -= $vmdata.MemoryAssigned
		$data+=$vmdata
	}
	
	$status = ""
	$hostdata = new-object -TypeName PSCustomOBject
	#create empty fields so array does not get issues
	$hostdata | Add-Member -MemberType NoteProperty -name ComputerName -value $($h.split(".")[0])
	$hostdata | Add-Member -MemberType NoteProperty -name "RAM" -value $($memory-2048)
	if($hostdata.RAM -lt $hvram) {$status+="Check HV RAM, "}
	$hostdata | Add-Member -MemberType NoteProperty -name "I/O (MB/s)" -value $($diskIO)
	$hostdata | Add-Member -MemberType NoteProperty -name Name                 -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name State               -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name "Status" -value $status
	$hostdata | Add-Member -MemberType NoteProperty -name ProcessorCount        -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name CPUUsage              -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name DynamicMemoryEnabled  -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name MemoryMaximum         -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name MemoryStartup       -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name MemoryMinimum        -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name MemoryAssigned       -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name MemoryDemand          -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name Uptime             -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name Version              -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name Generation          -value $null
	$hostdata | Add-Member -MemberType NoteProperty -name Path                -value $null


	$data+=$hostdata


}
format-table -inputobject $data	 -Wrap -AutoSize -Property *
