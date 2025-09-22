using 'windows.bicep'

param adminUsername = 'jordan'
@secure()
param adminPassword = loadTextContent('secrets/windows_password.txt')
param instanceCount = 2
param vmssName = 'win-vm'
param deploymentType = 'vmss'
param imageSku = '2022-Datacenter-Core'
param upgradePolicyMode = 'Rolling'
param scaleOutThreshold = 60
param scaleInThreshold = 20
param allowedAdminSourceAddress = '99.187.150.135'
param enableBootDiagnostics = true
param enableSystemAssignedIdentity = false
param enableAcceleratedNetworking = false
param tags = {
	environment: 'dev'
	workload: 'vmss-windows'
}
