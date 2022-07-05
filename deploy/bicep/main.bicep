// resource group 
@description('The location of the resource group and the location in which all resurces would be created')
param location string = resourceGroup().location

// storage

// Synapse workspace


@description('The suffix added to all resources to be created')
param suffix string 

module lake 'medalionlake.bicep' = {
  name: 'mylake'
  params: {
    suffix: suffix
    location: location
  }
}


