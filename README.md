# sample-mdw-serverless

End to end sample of data processing to be viewed in pbi

## Use Case

Contoso is an organization with multiple factories and multiple industrial lines. Periodicly factories need to upload data. The data is constructed of zipped JSON lines.
Contoso already developed a component named ControlBox, its capabilities (out of scope for this sample) are:

- Authenticate and authorize factories.

- Provide factories with SAS token, used by the factory to upload periodic data.

- Register new data uploaded in a control table.

Contoso, are looking for cost-effective solution, which will be able to provide Contoso Analytical team better view of the data.

## Suggested Architecture

The following diagram illustrate the solution suggested (and implemented) by Contoso. It leverages serverless computing for data movement, cleansing, restructure and reporting.

![architecture](./images/art.png)

### Bronze to Silver

Using a lookup step quering the control table and a copy activity the Synpase pipeline can process the new file drop. While the source reads the zipped multi line JSON files, the sink uses the parquet format, keeping the directory structure and file names.

![pipeline](./images/pipeline-b2s.png)

The parquet files can be queried using Synapse Serverless SQL Pool. Here is an example:

```sql
select * 
FROM
    OPENROWSET(
        BULK 'https://<storage-account-name>.dfs.core.windows.net/<container>/<folder>/**',
        FORMAT = 'PARQUET'
    ) AS [result]
```

### Silver to Gold

As described in this [document](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-tables-cetas) there are few initilization activities. In the following sections Serverless SQL pool is used.

#### Create a Database, master key & scopped credentials

```sql
-- Create a DB
CREATE DATABASE <db_name>
-- Create Master Key (if not already created)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<password>';
-- Create credentials
CREATE DATABASE SCOPED CREDENTIAL [factories_cred]
WITH IDENTITY='SHARED ACCESS SIGNATURE',  
SECRET = ''

```

In order to create SAS token, you can follow this [document](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens?tabs=Containers). Alternate solution in case you want one scopped credentials that can be used for the entire storage account. This can be created using the portal as well:

- Click on 'Shared Access Signeture' in the Security + Networking blads:

![blade](./images/blade.png)

- Select required operation, IP restrictions, dates etc:

![sas](./images/sas.png)

#### Create External File format

The following statment needs to be executed once per workspace:

```sql
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat') 
    CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat] 
    WITH ( FORMAT_TYPE = PARQUET)
GO
```

#### Create External Source

The following is creating an external data source, which will host the gold tables.

```sql
IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'gold') 
    CREATE EXTERNAL DATA SOURCE [gold] 
        WITH (
            LOCATION = 'abfss://<gold container>@<storage account>.dfs.core.windows.net' 
        )
GO
```

#### Create external table

Finally lets make use of the resources and data created, by creating the external table, this sample is essentially coping the entire content of all parquet files into a single table, this is the place where addtional aggregations, filtering can be applied.

```sql
CREATE EXTERNAL TABLE table_name
    WITH (
        LOCATION = '<specific location within the gold container>/',  
        DATA_SOURCE = [gold],
        FILE_FORMAT = [SynapseParquetFormat]  
)
    AS 
    select * 
    FROM
    OPENROWSET(
        BULK 'https://<storage account>.dfs.core.windows.net/<silver cobtainer>/<folder>/**',
        FORMAT = 'PARQUET'
    ) AS [result]

```

After this activity is completed, you can access the table using the serverless SQL pool, or from PowerBI.

