targetScope = 'subscription'

param resourceLocation string = 'italynorth'
param mainDnsZoneResourceId string
param mainCertKeyVaultResourceId string
param domain string

resource rgtemp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-temporary'
  location: resourceLocation
}

module certbotResources './certbot.bicep' = {
  scope: rgtemp
  name: '${uniqueString(deployment().name, resourceLocation)}-certbot'
  params: {
    resourceLocation: resourceLocation
    mainDnsZoneResourceId: mainDnsZoneResourceId
    mainCertKeyVaultResourceId: mainCertKeyVaultResourceId
  }
}

output umsi string = certbotResources.outputs.umsiResourceId
output registryServername string = certbotResources.outputs.registryServername
output azurednsini string = 'dns_azure_msi_client_id = ${certbotResources.outputs.umsiPrincipalId}\ndns_azure_zone1 = ${substring(domain, 2)}:${split(mainDnsZoneResourceId,'/providers')[0]}'
