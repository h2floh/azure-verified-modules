# Logic App SAP to SQL Integration Template

This Bicep template creates an Azure Logic App (Standard) that receives data from an SAP system and moves it to a SQL Database.

## Architecture

The template deploys the following Azure resources:

- **Logic App Standard** - Hosts the workflow that processes SAP data and writes to SQL
- **App Service Plan (WorkflowStandard)** - Provides compute resources for the Logic App
- **Storage Account** - Required for Logic App Standard runtime state and configuration
- **SQL Server** - Database server to store the SAP data
- **SQL Database** - Database to hold the processed SAP data
- **SQL Firewall Rule** - Allows Azure services to access the SQL Server

## Deployment

### Prerequisites

- Azure CLI or Azure PowerShell
- Bicep CLI
- An Azure subscription with appropriate permissions

### Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `resourceLocation` | string | Azure region for deployment | `swedencentral` |
| `sapConnectionString` | string | Connection string for SAP system | `''` |
| `sqlServerAdminLogin` | string | SQL Server administrator login | `sqladmin` |
| `sqlServerAdminPassword` | securestring | SQL Server administrator password | Required |

### Deploy the template

```bash
# Deploy using Azure CLI
az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
  --parameters sqlServerAdminPassword='YourSecurePassword123!'

# Deploy with custom parameters
az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
  --parameters resourceLocation='westeurope' \
               sqlServerAdminLogin='myadmin' \
               sqlServerAdminPassword='YourSecurePassword123!' \
               sapConnectionString='your-sap-connection-string'
```

## Workflow

The Logic App includes a sample workflow (`workflow.json`) that:

1. **Receives SAP Data** - HTTP trigger accepts JSON data from SAP system
2. **Parses Data** - Validates and extracts required fields
3. **Validates Fields** - Ensures required fields are present
4. **Inserts to SQL** - Calls stored procedure to insert data into SQL Database
5. **Returns Response** - Sends success/error response back to SAP system

### Expected SAP Data Format

```json
{
  "sapData": {
    "documentType": "INVOICE",
    "documentNumber": "INV-2024-001",
    "customerCode": "CUST001",
    "amount": 1500.00,
    "currency": "USD",
    "date": "2024-08-04T10:30:00Z",
    "description": "Product sale invoice"
  }
}
```

### SQL Database Setup

Create the following table and stored procedure in your SQL Database:

```sql
-- Create table to store SAP data
CREATE TABLE [dbo].[SAPData] (
    [Id] INT IDENTITY(1,1) PRIMARY KEY,
    [DocumentType] NVARCHAR(50) NOT NULL,
    [DocumentNumber] NVARCHAR(100) NOT NULL UNIQUE,
    [CustomerCode] NVARCHAR(50) NOT NULL,
    [Amount] DECIMAL(18,2) NOT NULL,
    [Currency] NVARCHAR(3) NOT NULL,
    [DocumentDate] DATETIME2 NOT NULL,
    [Description] NVARCHAR(500),
    [ProcessedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

-- Create stored procedure to insert data
CREATE PROCEDURE [dbo].[InsertSAPData]
    @DocumentType NVARCHAR(50),
    @DocumentNumber NVARCHAR(100),
    @CustomerCode NVARCHAR(50),
    @Amount DECIMAL(18,2),
    @Currency NVARCHAR(3),
    @DocumentDate DATETIME2,
    @Description NVARCHAR(500) = NULL,
    @ProcessedDate DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [dbo].[SAPData] (
        [DocumentType],
        [DocumentNumber],
        [CustomerCode],
        [Amount],
        [Currency],
        [DocumentDate],
        [Description],
        [ProcessedDate]
    )
    VALUES (
        @DocumentType,
        @DocumentNumber,
        @CustomerCode,
        @Amount,
        @Currency,
        @DocumentDate,
        @Description,
        @ProcessedDate
    );
END
```

## Configuration

After deployment:

1. **Configure SAP Connection** - Update the Logic App's SAP connection settings
2. **Set up SQL Connection** - The SQL connection string is automatically configured
3. **Deploy Workflow** - Upload the `workflow.json` to your Logic App
4. **Test Integration** - Send test data from SAP to verify the flow

## Security Considerations

- The SQL Server is configured to allow Azure services access
- Connection strings are stored as Logic App application settings
- Consider using Azure Key Vault for sensitive configurations
- Enable Azure AD authentication for SQL Server in production

## Monitoring

The Logic App provides built-in monitoring through:
- Run history and status tracking
- Azure Monitor integration
- Application Insights (optional)
- Diagnostic logs

## Customization

You can customize this template by:
- Adding additional data validation
- Implementing error handling and retry logic
- Adding transformation logic for SAP data
- Integrating with additional systems
- Adding authentication mechanisms

## Support

This template provides a foundation for SAP to SQL integration. Customize based on your specific SAP system configuration and data requirements.