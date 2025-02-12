targetScope = 'subscription'

param resourceLocation string = 'italynorth'

resource rgprivateaks 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-private-aks'
  location: resourceLocation
}

module mainResources './privateaks.bicep' = {
  scope: rgprivateaks
  name: 'internal'
  params: {
    resourceLocation: resourceLocation
    regionName: 'internal'
  }
}
