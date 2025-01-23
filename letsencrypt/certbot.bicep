param resourceLocation string = 'italynorth'
param mainDnsZoneResourceId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/dnszones/domain.com'
param mainCertKeyVaultResourceId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.KeyVault/vaults/vaultname'
param rgdns string = split(mainDnsZoneResourceId, '/')[4]

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-umsi'
  params: {
    // Required parameters
    name: 'umsi-${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    location: resourceLocation
    federatedIdentityCredentials: [
      {
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: 'https://token.actions.githubusercontent.com'
        name: 'GitHubWorkflowDefault'
        subject: 'repo:flowsoft-org/azure-verified-modules:ref:refs/heads/main'
      }
      {
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: 'https://token.actions.githubusercontent.com'
        name: 'GitHubWorkflowTest'
        subject: 'repo:flowsoft-org/azure-verified-modules:ref:refs/heads/h2floh/letsencrypt'
      }
    ]
  }
}

module registry 'br/public:avm/res/container-registry/registry:0.7.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-acr'
  params: {
    // Required parameters
    name: 'acr${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    acrSku: 'Basic'
    location: resourceLocation
    roleAssignments: [
      {
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'AcrPull'
      }
      {
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'AcrPush'
      }
    ]
  }
}

module dnsmsiRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dnsrole'
  scope: resourceGroup(rgdns)
  params: {
    // Required parameters
    principalId: userAssignedIdentity.outputs.principalId
    resourceId: mainDnsZoneResourceId
    roleDefinitionId: 'befefa01-2a29-4197-83a8-272ff33ce314' // 'DNS Zone Contributor'
    // Non-required parameters
    description: 'Role assignment for certbot'
    principalType: 'ServicePrincipal'
  }
}

module kvmsiRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-kvrole'
  scope: resourceGroup(rgdns)
  params: {
    // Required parameters
    principalId: userAssignedIdentity.outputs.principalId
    resourceId: mainCertKeyVaultResourceId
    roleDefinitionId: 'a4417e6f-fecd-4de8-b567-7b0420556985' // 'Key Vault Certificates Officer'
    // Non-required parameters
    description: 'Role assignment for certbot'
    principalType: 'ServicePrincipal'
  }
}


output registryServername string = registry.outputs.loginServer
output umsiResourceId string = userAssignedIdentity.outputs.resourceId
output umsiPrincipalId string = userAssignedIdentity.outputs.principalId
