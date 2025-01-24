targetScope = 'subscription'

param resourceLocation string = 'italynorth'
param mainCertKeyVaultResourceId string
param registryServername string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param email string
param domain string
param certname string
param production string = '0'

resource rgtemp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-temporary'
  location: resourceLocation
}

module containerGroup 'br/public:avm/res/container-instance/container-group:0.4.2' = {
  scope: rgtemp
  name: '${uniqueString(deployment().name, resourceLocation)}-aci'
  params: {
    // Required parameters
    containers: [
      {
        name: 'letsencrypt'
        properties: {
          image: '${registryServername}/h2floh/azurecertbot:latest'
          ports: [
            {
              port: 443
              protocol: 'Tcp'
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: '2'
            }
          }
          environmentVariables: [
            {
              name: 'YOUR_CERTIFICATE_EMAIL'
              value: email
            }
            {
              name: 'YOUR_DOMAIN'
              value: domain
            }
            {
              name: 'KEY_VAULT_NAME'
              value: split(mainCertKeyVaultResourceId, '/')[8]
            }
            {
              name: 'KEY_VAULT_CERT_NAME'
              value: certname
            }
            {
              name: 'PRODUCTION'
              value: production
            }         
            {
              name: 'USERNAME'
              value: userAssignedIdentityPrincipalId
            }
          ]
        }
      }
    ]
    name: 'aci-${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    ipAddressPorts: [
      {
        port: 443
        protocol: 'Tcp'
      }
    ]
    imageRegistryCredentials: [
      {
        server: registryServername
        identity: userAssignedIdentityResourceId
      }
    ]
    location: resourceLocation
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [userAssignedIdentityResourceId]
    }
    restartPolicy: 'Never'
  }
}

output aciResourceId string = containerGroup.outputs.resourceId
