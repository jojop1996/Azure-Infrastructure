@description('Primary region for all Azure resources.')
@minLength(1)
param location string = resourceGroup().location

module virtualMachineScaleSet 'br/public:avm/res/compute/virtual-machine-scale-set:0.11.0' = {
  name: 'virtualMachineScaleSetDeployment'
  params: {
    adminPassword: loadTextContent('temp/linux_password')
    adminUsername: 'scaleSetAdmin'
    imageReference: {
      id: '/subscriptions/95273533-6484-4c3f-b494-a7db2c17d6fd/resourceGroups/rg-packer-images/providers/Microsoft.Compute/images/ubuntu-24_04-lts-nginx'
    }
    name: 'cvmsslinmax001'
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
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Linux'
    skuName: 'Standard_D2s_v3'
    availabilityZones: [
      2
    ]
    bootDiagnosticEnabled: true
    disablePasswordAuthentication: true
    encryptionAtHost: false
    extensionMonitoringAgentConfig: {
      autoUpgradeMinorVersion: true
      enabled: true
    }
    extensionNetworkWatcherAgentConfig: {
      enabled: true
    }
    location: location
    publicKeys: [
      {
        keyData: loadTextContent('temp/id_rsa.pub')
        path: '/home/scaleSetAdmin/.ssh/authorized_keys'
      }
    ]
    scaleSetFaultDomain: 1
    skuCapacity: 2
    upgradePolicyMode: 'Automatic'
    vmNamePrefix: 'vmsslinvm'
    vmPriority: 'Regular'
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'virtualNetworkDeployment'
  params: {
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    name: 'nvnipam001'
    location: location
    subnets: [
      {
        addressPrefix: '10.0.0.0/24'
        name: 'subnet-1'
      }
    ]
  }
}

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.9.0' = {
  name: 'publicIpAddressDeployment'
  params: {
    name: 'npiamin001'
    location: location
    dnsSettings: {
      domainNameLabel: 'cvmsslindns'
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
    name: 'nlbext001'
    backendAddressPools: [
      {
        name: 'backendAddressPool1'
      }
      {
        name: 'backendAddressPool2'
      }
    ]
    inboundNatRules: [
      {
        name: 'sshNatPool'
        protocol: 'Tcp'
        frontendIPConfigurationName: 'publicIPConfig1'
        frontendPortRangeStart: 1000
        frontendPortRangeEnd: 1099
        backendPort: 22
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
        frontendPort: 80
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
    name: 'nnsgmax001'
    location: location
    securityRules: [
      {
        name: 'SSH-NSG'
        properties: {
          access: 'Allow'
          description: 'SSH remote access'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
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
  name: 'cpuautoscale'
  location: location
  properties: {
    name: 'cpuautoscale'
    targetResourceUri: virtualMachineScaleSet.outputs.resourceId
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
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
              threshold: 50
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
              threshold: 30
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
