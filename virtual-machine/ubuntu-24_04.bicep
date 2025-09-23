module virtualMachineScaleSet 'br/public:avm/res/compute/virtual-machine-scale-set:0.11.0' = {
  name: 'virtualMachineScaleSetDeployment'
  params: {
    // Required parameters
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
              publicIPAddressConfiguration: {
                name: 'pip-cvmsslinmax'
              }
              subnet: {
                id: virtualNetwork.outputs.subnetResourceIds[0]
              }
            }
          }
        ]
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
    // Non-required parameters
    availabilityZones: [
      2
    ]
    bootDiagnosticEnabled: true
    // bootDiagnosticStorageAccountName: '<bootDiagnosticStorageAccountName>'
    // dataDisks: [
    //   {
    //     caching: 'ReadOnly'
    //     createOption: 'Empty'
    //     diskSizeGB: 256
    //     lun: 1
    //     managedDisk: {
    //       storageAccountType: 'Premium_LRS'
    //     }
    //   }
    //   {
    //     caching: 'ReadOnly'
    //     createOption: 'Empty'
    //     diskSizeGB: 128
    //     lun: 2
    //     managedDisk: {
    //       storageAccountType: 'Premium_LRS'
    //     }
    //   }
    // ]
    // diagnosticSettings: [
    //   {
    //     eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
    //     eventHubName: '<eventHubName>'
    //     metricCategories: [
    //       {
    //         category: 'AllMetrics'
    //       }
    //     ]
    //     name: 'customSetting'
    //     storageAccountResourceId: '<storageAccountResourceId>'
    //     workspaceResourceId: '<workspaceResourceId>'
    //   }
    // ]
    disablePasswordAuthentication: true
    encryptionAtHost: false
    // extensionAzureDiskEncryptionConfig: {
    //   enabled: true
    //   settings: {
    //     EncryptionOperation: 'EnableEncryption'
    //     KekVaultResourceId: '<KekVaultResourceId>'
    //     KeyEncryptionAlgorithm: 'RSA-OAEP'
    //     KeyEncryptionKeyURL: '<KeyEncryptionKeyURL>'
    //     KeyVaultResourceId: '<KeyVaultResourceId>'
    //     KeyVaultURL: '<KeyVaultURL>'
    //     ResizeOSDisk: 'false'
    //     VolumeType: 'All'
    //   }
    // }
    // extensionCustomScriptConfig: {
    //   protectedSettings: {
    //     managedIdentityResourceId: '<managedIdentityResourceId>'
    //   }
    //   settings: {
    //     commandToExecute: '<commandToExecute>'
    //     fileUris: [
    //       '<storageAccountCSEFileUrl>'
    //     ]
    //   }
    // }
    // extensionDependencyAgentConfig: {
    //   enabled: true
    // }
    extensionMonitoringAgentConfig: {
      autoUpgradeMinorVersion: true
      enabled: true
    }
    extensionNetworkWatcherAgentConfig: {
      enabled: true
    }
    location: 'eastus'
    // lock: {
    //   kind: 'CanNotDelete'
    //   name: 'myCustomLockName'
    // }
    // managedIdentities: {
    //   systemAssigned: false
    //   userAssignedResourceIds: []
    // }
    publicKeys: [
      {
        keyData: loadTextContent('temp/id_rsa.pub')
        path: '/home/scaleSetAdmin/.ssh/authorized_keys'
      }
    ]
    // roleAssignments: [
    //   {
    //     name: '8abf72f9-e918-4adc-b20b-c783b8799065'
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: 'Owner'
    //   }
    //   {
    //     name: '<name>'
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    //   }
    //   {
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: '<roleDefinitionIdOrName>'
    //   }
    // ]
    scaleSetFaultDomain: 1
    skuCapacity: 1
    // tags: {
    //   Environment: 'Non-Prod'
    //   'hidden-title': 'This is visible in the resource name'
    //   Role: 'DeploymentValidation'
    // }
    upgradePolicyMode: 'Rolling'
    vmNamePrefix: 'vmsslinvm'
    vmPriority: 'Regular'
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'virtualNetworkDeployment'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    name: 'nvnipam001'
    // Non-required parameters
    location: 'eastus'
    subnets: [
      {
        addressPrefix: '10.0.0.0/24'
        name: 'subnet-1'
      }
      {
        addressPrefix: '10.0.1.0/24'
        name: 'subnet-2'
      }
      {
        addressPrefix: '10.0.2.0/24'
        name: 'subnet-3'
      }
    ]
  }
}
