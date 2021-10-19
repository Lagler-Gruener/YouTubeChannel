#Login into Azure:
az login

#Select right subscription
az account set --subscription <Subscription ID or Name>

#CLI command to get registry:
az acr show --resource-group rg-bicep  --name crbicepmodules 

#Upload Azure Bicep module
C:\Users\adminuser\.Azure\bin\bicep publish stracc.bicep --target 'br:crbicepmodules.azurecr.io/bicep/modules/storage:v1' #Use the full path because at the moment there is an issue with the bicep.exe file URL: https://github.com/Azure/bicep/releases


#Test deployment
az deployment group what-if --resource-group rg-bicep --template-file .\main.bicep
