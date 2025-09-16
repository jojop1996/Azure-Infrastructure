@description('The name of the Managed Cluster resource.')
param clusterName string

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

module aksModule 'tools/azure/bicep/modules/aks.bicep' = {
  name: 'aksDeployment'
  params: {
    clusterName: clusterName
    dnsPrefix: dnsPrefix
  }
}

output controlPlaneFQDN string = aksModule.outputs.controlPlaneFQDN
