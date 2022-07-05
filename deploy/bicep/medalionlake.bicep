param location string

param suffix string 

resource lake_storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'medalionlake${suffix}'
  location: location
  kind: 'StorageV2'
  properties:  {
    isHnsEnabled: true
  }
  sku: {
    name: 'Standard_LRS'
  }
}

resource bronze 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${lake_storage.name}/default/bronze'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

resource silver 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${lake_storage.name}/default/silver'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

resource gold 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name:  '${lake_storage.name}/default/gold'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}
