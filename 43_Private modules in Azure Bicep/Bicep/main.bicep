
var v_location = 'West Europe'

// The traditional way to use Azure Bicep Modules
/*
module deploystr 'Modules/stracc.bicep' = {
  name: 'deploy_stracc'
  params: {
    p_location: v_location
    p_storageAccountName: 'stracc${uniqueString(resourceGroup().id)}'
  }
}
*/

// Use Azure Private Repository with the full path
/*
module deploystr 'br:crbicepmodules.azurecr.io/bicep/modules/storage:v3' = {
  name: 'deploy_stracc'
  params: {
    p_location: v_location
    p_storageAccountName: 'stracc${uniqueString(resourceGroup().id)}'
  }
}
*/

// Use Azure Private Repository with the alias option

module deploystr 'br/PrivateModules:storage:v3' = {
  name: 'deploy_stracc'
  params: {
    p_location: v_location
    p_storageAccountName: 'stracc${uniqueString(resourceGroup().id)}'
  }
}
