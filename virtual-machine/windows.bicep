@description('Primary region for all Azure resources.')
@minLength(1)
param location string = resourceGroup().location

@description('Name of the virtual machine scale set.')
param vmssName string

@description('Admin username for the scale set.')
param adminUsername string

@description('Path to the admin password file.')
@secure()
param adminPassword string

@description('Image reference ID for the scale set.')
param imageReferenceId string

@description('OS disk size in GB.')
param osDiskSizeGB int

@description('OS disk storage account type.')
param osDiskStorageAccountType string

@description('VM SKU name.')
param vmSkuName string

@description('Availability zones.')
param availabilityZones array

@description('Scale set fault domain count.')
param scaleSetFaultDomain int

@description('Initial capacity of scale set.')
param skuCapacity int

@description('Upgrade policy mode.')
param upgradePolicyMode string

@description('VM name prefix.')
param vmNamePrefix string

@description('Virtual network name.')
param vnetName string

@description('Address prefixes for the virtual network.')
param vnetAddressPrefixes array

@description('Subnet name.')
param subnetName string

@description('Subnet address prefix.')
param subnetAddressPrefix string

@description('Public IP name.')
param publicIpName string

@description('DNS label for the public IP.')
param dnsLabelName string

@description('Load balancer name.')
param loadBalancerName string

@description('Network security group name.')
param nsgName string

@description('Auto-scale settings name.')
param autoScaleSettingsName string

@description('Auto-scale minimum capacity.')
param autoScaleMinimum string

@description('Auto-scale maximum capacity.')
param autoScaleMaximum string

@description('Auto-scale default capacity.')
param autoScaleDefault string

@description('CPU threshold to scale up.')
param cpuThresholdToScaleUp int

@description('CPU threshold to scale down.')
param cpuThresholdToScaleDown int

module virtualMachineScaleSet 'br/public:avm/res/compute/virtual-machine-scale-set:0.11.0' = {
  name: 'virtualMachineScaleSetDeployment'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    imageReference: {
      id: imageReferenceId
    }
    name: vmssName
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig1'
            properties: {
              subnet: {
                id: virtualNetwork.outputs.subnetResourceIds[0]
              }
              loadBalancerBackendAddressPools: [
                {
                  id: '${loadBalancer.outputs.resourceId}/backendAddressPools/backendAddressPool1'
                }
              ]
            }
          }
        ]
        networkSecurityGroupResourceId: networkSecurityGroup.outputs.resourceId
        nicSuffix: '-nic01'
      }
    ]
    osDisk: {
      createOption: 'fromImage'
      diskSizeGB: osDiskSizeGB
      managedDisk: {
        storageAccountType: osDiskStorageAccountType
      }
    }
    osType: 'Windows'
    skuName: vmSkuName
    availabilityZones: availabilityZones
    bootDiagnosticEnabled: true
    disablePasswordAuthentication: false
    encryptionAtHost: false
    extensionMonitoringAgentConfig: {
      autoUpgradeMinorVersion: true
      enabled: true
    }
    extensionNetworkWatcherAgentConfig: {
      enabled: true
    }
    location: location
    scaleSetFaultDomain: scaleSetFaultDomain
    skuCapacity: skuCapacity
    upgradePolicyMode: upgradePolicyMode
    vmNamePrefix: vmNamePrefix
    vmPriority: 'Regular'
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'virtualNetworkDeployment'
  params: {
    addressPrefixes: vnetAddressPrefixes
    name: vnetName
    location: location
    subnets: [
      {
        addressPrefix: subnetAddressPrefix
        name: subnetName
      }
    ]
  }
}

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.9.0' = {
  name: 'publicIpAddressDeployment'
  params: {
    name: publicIpName
    location: location
    dnsSettings: {
      domainNameLabel: dnsLabelName
      domainNameLabelScope: 'ResourceGroupReuse'
      fqdn: 'testdns'
    }
  }
}

module loadBalancer 'br/public:avm/res/network/load-balancer:0.4.2' = {
  name: 'loadBalancerDeployment'
  params: {
    frontendIPConfigurations: [
      {
        name: 'publicIPConfig1'
        publicIPAddressId: publicIpAddress.outputs.resourceId
      }
    ]
    name: loadBalancerName
    backendAddressPools: [
      {
        name: 'backendAddressPool1'
      }
    ]
    inboundNatRules: [
      {
        name: 'rdpNatPool'
        protocol: 'Tcp'
        frontendIPConfigurationName: 'publicIPConfig1'
        frontendPortRangeStart: 1000
        frontendPortRangeEnd: 1099
        backendPort: 3389
        backendAddressPoolName: 'backendAddressPool1'
      }
    ]
    loadBalancingRules: [
      {
        backendAddressPoolName: 'backendAddressPool1'
        backendPort: 80
        disableOutboundSnat: true
        enableFloatingIP: false
        enableTcpReset: false
        frontendIPConfigurationName: 'publicIPConfig1'
        frontendPort: 443
        idleTimeoutInMinutes: 5
        loadDistribution: 'Default'
        name: 'publicIPLBRule1'
        probeName: 'probe1'
        protocol: 'Tcp'
      }
    ]
    location: location
    probes: [
      {
        intervalInSeconds: 10
        name: 'probe1'
        numberOfProbes: 5
        port: 80
        protocol: 'Http'
        requestPath: '/http-probe'
      }
      {
        name: 'probe2'
        port: 443
        protocol: 'Https'
        requestPath: '/https-probe'
      }
    ]
  }
}

module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: 'networkSecurityGroupDeployment'
  params: {
    name: nsgName
    location: location
    securityRules: [
      {
        name: 'RDP-NSG'
        properties: {
          access: 'Allow'
          description: 'RDP remote access'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

resource autoScaleSettings 'microsoft.insights/autoscalesettings@2015-04-01' = {
  name: autoScaleSettingsName
  location: location
  properties: {
    name: autoScaleSettingsName
    targetResourceUri: virtualMachineScaleSet.outputs.resourceId
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: autoScaleMinimum
          maximum: autoScaleMaximum
          default: autoScaleDefault
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: virtualMachineScaleSet.outputs.resourceId
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: cpuThresholdToScaleUp
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: virtualMachineScaleSet.outputs.resourceId
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: cpuThresholdToScaleDown
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}
