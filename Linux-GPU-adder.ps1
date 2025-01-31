
$vmobject = Get-VM | Out-GridView -Title "Select VM to setup GPU-P" -OutputMode Single
$vm = $vmobject.Name

$dev = Get-PnpDevice -Class Display -Status OK | Out-GridView -Title "Select Card to setup GPU-P" -OutputMode Single

$props = $dev | Get-PnpDeviceProperty
$pnpinf = ($props | where {$_.KeyName -eq "DEVPKEY_Device_DriverInfPath"}).Data
$infsection = ($props | where {$_.KeyName -eq "DEVPKEY_Device_DriverInfSection"}).Data
$cbsinf = (Get-WindowsDriver -Online | where {$_.Driver -eq "$pnpinf"}).OriginalFileName
If (-not $cbsinf) {
	Write-Host "Device not supported: $dev, inf: $pnpinf, cbs: $cbsinf"
	return;
}

$gpuName = $dev.FriendlyName
$path = "\\?\" + $dev.InstanceId.replace('\', '#').ToLower() + "#{064092b3-625e-43bf-9eb5-dc845897dd59}\GPUPARAV"



#Configure GPU for VM
Add-VMGpuPartitionAdapter -VMName $vm -InstancePath "$path"
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionVRAM 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionVRAM 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionVRAM 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionEncode 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionEncode 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionEncode 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionDecode 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionDecode 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionDecode 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionCompute 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionCompute 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionCompute 10
Set-VM -GuestControlledCacheTypes $true -VMName $vm
Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $vm
Set-VM -HighMemoryMappedIoSpace 32GB -VMName $vm


echo "ALL DONE, ENJOY"
