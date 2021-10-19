
param p_storageAccountName string
param p_location string


resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: p_storageAccountName
  location: p_location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
