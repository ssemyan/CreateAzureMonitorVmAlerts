# Create Azure Monitor VM Alerts

**Note: This project uses the [new style of alert in Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/alerts-overview). For classic style alerts, refer to https://github.com/ssemyan/CreateClassicAzureVmAlerts**

**Note 2: This template only works for Windows VMs**

This PowerShell script and ARM templates will create alerts in Azure Monitor for each VM using that email specified addresses when:

1. The memory usage of the VM exceeds 80% for 5 minutes
1. The CPU usage of the VM exceeds 80% for 5 minutes
1. The network in of the VM falls below 15K for 5 minutes

These scripts follow the methods for alerting described here: 
* [Azure Monitor Alerts](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/alerts-overview)
* [Sending guest OS metrics to Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/collect-custom-metrics-guestos-resource-manager-vm)
* [Create a metric alert with a Resource Manager template](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/alerts-metric-create-templates)

The PowerShell script will set these alerts for every VM in the specified resource groups. This requires the following:

1. [Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/overview?view=azps-1.3.0) Note: if using the newer version the script will set the AzureRm alias via _Enable-AzureRmAlias_.
1. VM Guest Diagnostics extension to be installed with _Azure Monitor as a sink_. Learn more about this here: https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/diagnostics-windows
1. Managed Service Identity to be enabled for the VM so it can send metrics to Azure Monitor. Learn more about this here: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/

You can enable a Managed Service Identity for a VM using the following PowerShell commands:

```
$rg = 'resource_group_name'
$vm = Get-AzVm -ResourceGroupName $rg -Name myvm
Update-AzVM -ResourceGroupName $rg -VM $vm -AssignIdentity:$SystemAssigned
```

To remove the Managed Service Identity:

```
$rg = 'resource_group_name'
$vm = Get-AzVm -ResourceGroupName $rg -Name myvm
Update-AzVM -ResourceGroupName $rg -VM $vm -IdentityType None
```

To install the **Windows** VM Extension while creating the alerts, set the value of _$addExtension_ to _$TRUE_ and update the values for _$existingdiagnosticsStorageAccountName_ and _$existingdiagnosticsStorageResourceGroup_

To only install the extension and not create alerts, set the value of _$addAlerts_ to _$FALSE_

To use this script edit the details in _CreateAlertsOnAllVmsInResourceGroups.ps1_:

First update the list of resource groups to search:
```
$resourceGroupsToProcess = @('my_group', 'my_group_2')
```

Alternatively, if you want to run against **all resource groups** uncomment out this line:
```
#$resourceGroupsToProcess = @()
```

Then update the email(s) to send alerts to (comma-separated if more than one):
```
$sendToEmails = 'myemail@company.com,myemail2@company.com'
```

Finally, run the following command in PowerShell. 
```
.\CreateAlertsOnAllVmsInResourceGroups.ps1
```
