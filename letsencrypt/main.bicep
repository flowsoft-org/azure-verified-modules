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

output umsiResourceId string = certbotResources.outputs.umsiResourceId
output umsiPrincipalId string = certbotResources.outputs.umsiPrincipalId
output registryServername string = certbotResources.outputs.registryServername
output azurednsini string = 'dns_azure_use_cli_credentials = true\ndns_azure_environment = "AzurePublicCloud"\ndns_azure_zone1 = ${domain}:${split(mainDnsZoneResourceId,'/providers')[0]}'
