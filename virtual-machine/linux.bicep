
@description('The name of your Virtual Machine or VM Scale Set.')
param vmName string

@description('Username for the Virtual Machine(s).')
param adminUsername string

@description('Name for the SSH public key resource.')
param sshKeyName string = 'linux-admin-key'

@description('The SSH public key content.')
@secure()
param sshPublicKey string

@description('Number of VM instances (for scale set).')
@minValue(1)
@maxValue(100)
param instanceCount int = 2

@description('Deployment type: single VM or scale set.')
@allowed([
  'vm'
  'vmss'
])
param deploymentType string = 'vmss'

@description('Publisher of the Linux image.')
@allowed([
  'Canonical'
])
param imagePublisher string = 'Canonical'

@description('Offer of the Windows image.')
@allowed([
  'UbuntuServer'
])
param imageOffer string = 'UbuntuServer'

@description('The Linux version for the VM(s).')
@allowed([
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param imageSku string

@description('Version of the Windows image.')
param imageVersion string = 'latest'

@description('Upgrade policy mode for VMSS (Manual, Automatic, Rolling).')
@allowed([
  'Manual'
  'Automatic'
  'Rolling'
])
param upgradePolicyMode string = 'Rolling'

@description('CPU percentage threshold to trigger scale-out (increase instance count).')
@minValue(1)
@maxValue(100)
param scaleOutThreshold int = 60

@description('CPU percentage threshold to trigger scale-in (decrease instance count).')
@minValue(1)
@maxValue(100)
param scaleInThreshold int = 20

@description('Allow inbound admin access (SSH) only from this source. Use CIDR or IP. Default is open (not recommended for production).')
param allowedAdminSourceAddress string = '*'

@description('Enable boot diagnostics on VM/VMSS for troubleshooting.')
param enableBootDiagnostics bool = true

@description('Enable system-assigned managed identity on VM/VMSS.')
param enableSystemAssignedIdentity bool = false

@description('Enable accelerated networking on NICs when supported by VM size.')
param enableAcceleratedNetworking bool = false

@description('Tags applied to all resources created by this deployment.')
param tags object = {}

module sshKeyModule '../../azure-tools/bicep/modules/ssh-key.bicep' = {
  name: 'sshKey'
  params: {
    sshKeyName: sshKeyName
    sshPublicKey: sshPublicKey
  }
}

module vmModule '../../azure-tools/bicep/modules/virtual-machine.bicep' = {
  name: 'vmDeployment'
  params: {
    vmName: vmName
    platform: 'Linux'
    adminUsername: adminUsername
    authenticationType: 'sshPublicKey'
    adminPasswordOrKey: sshPublicKey
    deploymentType: deploymentType
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
