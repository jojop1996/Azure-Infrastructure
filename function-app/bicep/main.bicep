@description('The name for your deployed function app.')
param appName string

@description('Language runtime used by the function app.')
@allowed(['dotnet-isolated','python','java', 'node', 'powerShell'])
param appRuntime string

@description('Target language version used by the function app.')
param appRuntimeVersion string

@description('The type of hosting plan to use for the function app.')
@allowed(['FlexConsumption', 'Consumption', 'Premium'])
param planType string

module functionApp '../tools/azure/bicep/modules/functionApp.bicep' = {
  name: 'functionAppDeployment'
  params: {
    appName: appName
    appRuntime: appRuntime
    appRuntimeVersion: appRuntimeVersion
    planType: planType
  }
}
