using '../windows.bicep'

param vmssName = 'vmss-win-datacenter'
param adminUsername = 'scaleSetAdmin'
param adminPassword = loadTextContent('../temp/windows_password')
param imageReferenceId = '/subscriptions/95273533-6484-4c3f-b494-a7db2c17d6fd/resourceGroups/rg-packer-images/providers/Microsoft.Compute/images/win-datacenter-2025-nginx'
param osDiskSizeGB = 128
param osDiskStorageAccountType = 'Standard_LRS'
param vmSkuName = 'Standard_D2s_v3'
param availabilityZones = [2]
param scaleSetFaultDomain = 1
param skuCapacity = 2
param upgradePolicyMode = 'Automatic'
param vmNamePrefix = 'vm-win-dc'
param vnetName = 'vn-win-datacenter'
param vnetAddressPrefixes = ['10.0.0.0/16']
param subnetName = 'subnet-1'
param subnetAddressPrefix = '10.0.0.0/24'
param publicIpName = 'pi-win-datacenter'
param dnsLabelName = 'dns-win-datacenter'
param loadBalancerName = 'lb-win-datacenter'
param nsgName = 'nsg-win-datacenter'
param autoScaleSettingsName = 'as-win-datacenter'
param autoScaleMinimum = '1'
param autoScaleMaximum = '2'
param autoScaleDefault = '1'
param cpuThresholdToScaleUp = 50
param cpuThresholdToScaleDown = 30
