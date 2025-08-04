@description('The name of the Logic App')
param logicAppName string

@description('The location for the Logic App')
param location string = resourceGroup().location

@description('The SAP connection details')
param sapConnection object = {
  serverName: ''
  systemNumber: ''
  clientId: ''
  username: ''
  gatewayName: ''
}

@description('The SQL Server connection details')
param sqlConnection object = {
  serverName: ''
  databaseName: ''
  username: ''
}

@description('Tags to be applied to the resources')
param tags object = {}

// SQL Server connection
resource sqlServerConnection 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: '${logicAppName}-sql'
  location: location
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sql')
    }
    displayName: 'SQL Server Connection'
    parameterValues: {
      server: sqlConnection.serverName
      database: sqlConnection.databaseName
      username: sqlConnection.username
    }
  }
  tags: tags
}

// SAP connection
resource sapServerConnection 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: '${logicAppName}-sap'
  location: location
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sap')
    }
    displayName: 'SAP Connection'
    parameterValues: {
      serverName: sapConnection.serverName
      systemNumber: sapConnection.systemNumber
      clientId: sapConnection.clientId
      userName: sapConnection.username
      gatewayName: sapConnection.gatewayName
    }
  }
  tags: tags
}

// Logic App
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        sapTrigger: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sap\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/datasets/@{encodeURIComponent(encodeURIComponent(\'default\'))}/tables/@{encodeURIComponent(encodeURIComponent(\'YOUR_SAP_TABLE\'))}/onchanged'
          }
          recurrence: {
            frequency: 'Minute'
            interval: 5
          }
        }
      }
      actions: {
        'Insert_row': {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/datasets/@{encodeURIComponent(encodeURIComponent(\'default\'))}/tables/@{encodeURIComponent(encodeURIComponent(\'[dbo].[YourTable]\'))}/items'
            body: '@triggerBody()'
          }
          runAfter: {}
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          sap: {
            connectionId: sapServerConnection.id
            connectionName: sapServerConnection.name
            id: sapServerConnection.properties.api.id
          }
          sql: {
            connectionId: sqlServerConnection.id
            connectionName: sqlServerConnection.name
            id: sqlServerConnection.properties.api.id
          }
        }
      }
    }
  }
  tags: tags
}
