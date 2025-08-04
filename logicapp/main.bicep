targetScope = 'resourceGroup'

@description('The name prefix for all resources')
param namePrefix string

@description('The location for all resources')
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

@description('Tags to be applied to all resources')
param tags object = {
  environment: 'production'
  application: 'sap-to-sql-integration'
}

// Deploy the Logic App
module logicApp 'logicapp.bicep' = {
  name: 'logicAppDeployment'
  params: {
    logicAppName: '${namePrefix}-logicapp'
    location: location
    sapConnection: sapConnection
    sqlConnection: sqlConnection
    tags: tags
  }
}
