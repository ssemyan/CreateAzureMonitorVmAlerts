# Create array of resource groups we want to process 
$resourceGroupsToProcess = @('my_group', 'my_group_2')
$sendToEmails = 'myemail@company.com,myotheremail@company.com'

# To process all resource groups uncomment out the next line - NOTE: THIS WILL INSTALL THE DIAGNOSTIC EXTENSION AND CREATE ALERTS FOR EVERY VM IN YOUR SUBSCRIPTION
#$resourceGroupsToProcess = @()

# To add the IaaSDiagnostics extension to the VM, change the next line to $TRUE and set the storage variables appropriately
$addExtension = $FALSE
$existingdiagnosticsStorageAccountName = 'mystorageaccount'
$existingdiagnosticsStorageResourceGroup = 'mystorageaccountresourcegroup'

# To disable adding alerts, set the next line to $FALSE
$addAlerts = $TRUE

# Enable the AzureRM alias if not already set
$alias = Get-Command Get-AzureRmResourceGroup -errorAction SilentlyContinue
if (-Not $alias) {
  Write-Host Enabling AzureRm Alias
  Enable-AzureRmAlias -Scope Process
}

$allresgroup = Get-AzureRmResourceGroup
  
foreach ($rg in $allresgroup)
{
    Write-Host Processing resource group: $rg.ResourceGroupName
    
	if (($resourceGroupsToProcess.Length -eq 0) -or ($rg.ResourceGroupName -in $resourceGroupsToProcess))
	{
		# Get List of VMs in current resource group
		$vms = Get-AzureRmVM -ResourceGroupName $rg.ResourceGroupName
		foreach ($vm in $vms)
		{
			if ($addExtension)
			{
				Write-Host Enable IaaSDiagnostics extension for VM: $vm.Name 
				New-AzureRMResourceGroupDeployment -Name diag_ext_$($vm.Name) -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\diag_template.json -virtualMachineName $vm.Name `
												   -existingdiagnosticsStorageAccountName $existingdiagnosticsStorageAccountName -existingdiagnosticsStorageResourceGroup $existingdiagnosticsStorageResourceGroup -Verbose
			}

			if ($addAlerts)
			{
				Write-Host Creating action group for VM: $vm.Name 
				$agDeploy = New-AzureRMResourceGroupDeployment -Name action_grp_$($vm.Name) -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\alert_action_group.json -virtualMachineName $vm.Name -sendToEmails $sendToEmails -Verbose
				$agResourceId = $agDeploy.Outputs.actionGroupId.value

				Write-Host Creating alerts for VM: $vm.Name

				# run ARM template against VM for memory alert
				New-AzureRMResourceGroupDeployment -Name mem_alert_$($vm.Name) -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\alert_memory_template.json -virtualMachineName $vm.Name -actionGroupId $agResourceId -Verbose

				# run ARM template against VM for CPU alert
				New-AzureRMResourceGroupDeployment -Name cpu_alert_$($vm.Name) -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\alert_cpu_template.json -virtualMachineName $vm.Name -actionGroupId $agResourceId -Verbose

				# run ARM template against VM for network alert
				New-AzureRMResourceGroupDeployment -Name net_alert_$($vm.Name) -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\alert_network_template.json -virtualMachineName $vm.Name -actionGroupId $agResourceId -Verbose
			}
		}
	}
	else
	{
		Write-Host Ignoring resource group.
	}
}
 