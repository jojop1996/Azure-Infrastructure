@description('Admin username for the Windows VM.')
param adminUsername string

@description('Admin password for the Windows VM.')
@secure()
param adminPassword string

@description('Number of VM instances (for scale set).')
param instanceCount int = 1

@description('Name of the VM or VM Scale Set.')
param vmssName string = 'win-vm'

@description('Publisher of the Windows image.')
@allowed([
  'MicrosoftWindowsServer'
])
param imagePublisher string = 'MicrosoftWindowsServer'

@description('Offer of the Windows image.')
@allowed([
  'WindowsServer'
])
param imageOffer string = 'WindowsServer'

@description('The Windows version for the VM(s).')
@allowed([
  '2019-Datacenter'
  '2022-Datacenter'
  '2019-Datacenter-Core'
  '2022-Datacenter-Core'
  '2019-Datacenter-Gen2'
  '2022-Datacenter-Gen2'
])
param imageSku string

@description('Version of the Windows image.')
param imageVersion string = 'latest'

@description('CPU percentage threshold to trigger scale-out (increase instance count).')
@minValue(1)
@maxValue(100)
param scaleOutThreshold int = 50

@description('CPU percentage threshold to trigger scale-in (decrease instance count).')
@minValue(1)
@maxValue(100)
param scaleInThreshold int = 30

@description('Upgrade policy mode for VMSS (Manual, Automatic, Rolling).')
@allowed([
  'Manual'
  'Automatic'
  'Rolling'
])
param upgradePolicyMode string = 'Manual'

@description('Deployment type: single VM or scale set.')
@allowed([
  'vm'
  'vmss'
])
param deploymentType string = 'vm'

@description('Allow inbound admin access (RDP) only from this source. Use CIDR or IP. Default is open (not recommended for production).')
param allowedAdminSourceAddress string = '*'

@description('Enable boot diagnostics on VM/VMSS for troubleshooting.')
param enableBootDiagnostics bool = true

@description('Enable system-assigned managed identity on VM/VMSS.')
param enableSystemAssignedIdentity bool = false

@description('Enable accelerated networking on NICs when supported by VM size.')
param enableAcceleratedNetworking bool = false

@description('Tags applied to all resources created by this deployment.')
param tags object = {}

module vmModule '../../azure-tools/bicep/modules/virtual-machine.bicep' = {
  name: 'vmDeployment'
  params: {
    vmName: vmssName
    deploymentType: deploymentType
    platform: 'Windows'
    adminUsername: adminUsername
    authenticationType: 'password'
    adminPasswordOrKey: adminPassword
    instanceCount: instanceCount
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageSku: imageSku
    imageVersion: imageVersion
    upgradePolicyMode: upgradePolicyMode
    scaleOutThreshold: scaleOutThreshold
    scaleInThreshold: scaleInThreshold
    allowedAdminSourceAddress: allowedAdminSourceAddress
    enableBootDiagnostics: enableBootDiagnostics
    enableSystemAssignedIdentity: enableSystemAssignedIdentity
    enableAcceleratedNetworking: enableAcceleratedNetworking
    tags: tags
  }
}

output fqdn string = vmModule.outputs.fqdn
