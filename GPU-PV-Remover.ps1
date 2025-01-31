# Remove current GPU-P adapter
$vmobject = Get-VM | Out-GridView -Title "Select VM to setup GPU-P" -OutputMode Single
$vm = $vmobject.Name

Remove-VMGpuPartitionAdapter -VMName $vm

echo "ALL DONE, ENJOY"
