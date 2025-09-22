
using 'linux.bicep'

// Base VM configuration
param vmName = 'ubuntu-jammy'
param adminUsername = 'jordan'
param sshKeyName = 'ubuntu-jammy-public-key'
@secure()
param sshPublicKey = loadTextContent('secrets/keys/id_rsa.pub')

// VMSS and autoscaling configuration
param deploymentType = 'vmss'
param instanceCount = 2
param imageSku = 'Ubuntu-2204'
param upgradePolicyMode = 'Rolling'
param scaleOutThreshold = 60
param scaleInThreshold = 20

// Networking and diagnostics
param allowedAdminSourceAddress = '99.187.150.135'
param enableBootDiagnostics = true
param enableSystemAssignedIdentity = false
param enableAcceleratedNetworking = false

// Tags
param tags = {
	environment: 'dev'
	workload: 'vmss-linux'
}
