# SAP to SQL Logic App Integration

This module creates a Logic App that automatically synchronizes data from an SAP system to an Azure SQL Database. The Logic App monitors changes in a specified SAP table and automatically copies the data to a corresponding SQL table.

## Prerequisites

Before deploying this module, ensure you have:

1. **SAP System Requirements**
   - An operational SAP system
   - On-premises Data Gateway installed and configured
   - SAP client credentials (Client ID, username, system number)
   - Network connectivity between the gateway and SAP system

2. **Azure SQL Requirements**
   - An existing Azure SQL Server and database
   - SQL Server credentials
   - Proper network access configured (firewall rules or private endpoints)

## Architecture

The solution consists of the following components:
- Logic App workflow for orchestration
- SAP connector for source data access
- SQL connector for target data storage
- On-premises Data Gateway for SAP connectivity

```
[SAP System] <-> [On-premises Data Gateway] <-> [Logic App] <-> [Azure SQL Database]
```

## Module Resources

This module deploys:
- Microsoft.Logic/workflows (Logic App)
- Microsoft.Web/connections (SAP and SQL connections)

## Parameters

### Required Parameters
- `namePrefix`: Prefix for resource names
- `sapConnection.serverName`: SAP server hostname or IP
- `sapConnection.systemNumber`: SAP system number
- `sapConnection.clientId`: SAP client ID
- `sapConnection.username`: SAP username
- `sapConnection.gatewayName`: On-premises Data Gateway name
- `sqlConnection.serverName`: SQL Server name
- `sqlConnection.databaseName`: Database name
- `sqlConnection.username`: SQL username

### Optional Parameters
- `location`: Azure region (defaults to resource group location)
- `tags`: Resource tags

## Usage

1. **Basic deployment**
```bicep
module logicApp './logicapp/main.bicep' = {
  name: 'sapToSqlLogicApp'
  params: {
    namePrefix: 'sap2sql'
    sapConnection: {
      serverName: 'sap.contoso.com'
      systemNumber: '00'
      clientId: '100'
      username: 'sapuser'
      gatewayName: 'contoso-gateway'
    }
    sqlConnection: {
      serverName: 'sql.database.windows.net'
      databaseName: 'targetdb'
      username: 'sqluser'
    }
  }
}
```

2. **Deployment with custom settings**
```bicep
module logicApp './logicapp/main.bicep' = {
  name: 'sapToSqlLogicApp'
  params: {
    namePrefix: 'sap2sql'
    location: 'westeurope'
    sapConnection: {
      serverName: 'sap.contoso.com'
      systemNumber: '00'
      clientId: '100'
      username: 'sapuser'
      gatewayName: 'contoso-gateway'
    }
    sqlConnection: {
      serverName: 'sql.database.windows.net'
      databaseName: 'targetdb'
      username: 'sqluser'
    }
    tags: {
      environment: 'production'
      costCenter: 'IT'
    }
  }
}
```

## Post-Deployment Configuration

After deployment:

1. **Configure Connections**
   - Navigate to the Logic App in Azure Portal
   - Open the API Connections
   - Authenticate both SAP and SQL connections with credentials

2. **Configure SAP Table**
   - Edit the Logic App workflow
   - In the SAP trigger, specify the actual SAP table name
   - Configure any required filters or conditions

3. **Configure SQL Table**
   - Ensure the target SQL table exists with appropriate schema
   - Update the SQL action with the correct table name
   - Map SAP fields to SQL columns if needed

4. **Testing**
   - Make a change in the SAP table
   - Monitor the Logic App runs
   - Verify data appears in SQL table

## Security Considerations

- Store credentials in Key Vault and use managed identities
- Use private endpoints for SQL connectivity
- Implement least privilege access for SAP and SQL accounts
- Enable diagnostic logs for monitoring and auditing
- Consider implementing data validation and error handling

## Limitations

- SAP table changes are detected every 5 minutes (configurable)
- Requires On-premises Data Gateway for SAP connectivity
- Single direction sync (SAP to SQL only)
- Simple 1:1 table mapping (customize for complex scenarios)
