@description('Specifies the name of the key vault.')
param key_vault_name string 

@description('Specifies the Azure location where the key vault should be created.')
param location string 

param SynapseIdentityObjId string

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = false

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param userObjId string



var roleIdMapping = {
  'Key Vault Administrator': '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  'Key Vault Certificates Officer': 'a4417e6f-fecd-4de8-b567-7b0420556985'
  'Key Vault Crypto Officer': '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
  'Key Vault Crypto Service Encryption User': 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
  'Key Vault Crypto User': '12338af0-0e69-4776-bea7-57ae8d297424'
  'Key Vault Reader': '21090545-7ca7-4776-b22c-e363652d74d2'
  'Key Vault Secrets Officer': 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
  'Key Vault Secrets User': '4633458b-17de-408a-b874-0445c86b69e6'
  'Owner': '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}



resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: key_vault_name
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableRbacAuthorization: true
    tenantId: tenantId

    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

param secretUser string = 'Key Vault Secrets User'
resource SecretUserAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleIdMapping[secretUser],SynapseIdentityObjId,kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIdMapping[secretUser])
    principalId: SynapseIdentityObjId
    principalType: 'ServicePrincipal'
  }
}


param adminRole string = 'Key Vault Administrator'
resource adminAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleIdMapping[adminRole],userObjId,kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIdMapping[adminRole])
    principalId: userObjId
    principalType: 'User'
  }
}


param ownerRole string = 'Owner'
resource ownerAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleIdMapping[ownerRole],userObjId,kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIdMapping[ownerRole])
    principalId: userObjId
    principalType: 'User'
  }
}

param accountKeySecretName string = 'medalion-acc-key'
param accountConnStringSecretName string = 'medalion-acc-cs'

param accountKeySecretValue string
param accountCSSecretValue string

resource accsecret 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: kv
  name: accountKeySecretName
  properties: {
    value: accountKeySecretValue
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: kv
  name: accountConnStringSecretName
  properties: {
    value: accountCSSecretValue
  }
}

output key_vault_name string = kv.name
