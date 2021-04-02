<#
    SYNOPSIS
        This script is used to demonstrate an azure PSE Architecture
    .DESCRIPTION
        This script is used to demonstrate an azure PSE Architecture
    .EXAMPLE
        
    .NOTES  
        Please install the latest Az Modules!
        Please also install AzureRM.Profile module
#>

#######################################################################################################################
#region define global variables

$accesstoken = ""

#$resourcegroup = "rg-psedemo"
$resourcegroup = "Global-Azure-BootCamp-2020-IaaS-PaaS"
$location = "West Europe"
$vnetname = "vnetpsedemo01"

$sqlservername = "sqldemopse2"
$sqldatabasename = "demopsedb2"

$appsvcplanname = "demopseappsvcp2"
$webappname = "demowebapppse2"

$keyvaultname = "demopsekeyvault2"
$keyvaultsecretname = "dbconnectdemopse2"

$ErrorActionPreference = 'Stop'

#endregion
#######################################################################################################################


#######################################################################################################################
#region Functions

#login to azure and get access token
function Login-Azure()
{
    try 
    {
        if(-not (Get-Module Az.Accounts)) {
            Import-Module Az.Accounts
        }
    
        Connect-AzAccount               
    }
    catch {
        Write-Error "Error in function Login-Azure. Error message: $($_.Exception.Message)"
    }
}

function Get-AzCachedAccessToken()
{
    try {
        if(-not (Get-Module Az.Accounts)) {
            Import-Module Az.Accounts
        }
        $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        if(-not $azProfile.Accounts.Count) {
            Write-Error "Ensure you have logged in before calling this function."    
        }
      
        $currentAzureContext = Get-AzContext
        $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
        Write-Debug ("Getting access token for tenant" + $currentAzureContext.Tenant.TenantId)
        $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
        $token.AccessToken        
    }
    catch {
        Write-Error "Error in function Get-AzCachedAccessToken. Error message: $($_.Exception.Message)"
    }    
}

#endregion
#######################################################################################################################


#######################################################################################################################
#region Script start
    Clear-AzContext -Force

    Write-Host "#######################################################################"
    $sqlservercredential = Get-Credential -Message "Please enter sql server credential"
    Write-Host "#######################################################################"

    Write-Host "Connect to Azure"
    Login-Azure

    #region section select subscription
    try 
    {            
        $subscriptions = Get-AzSubscription

        if (($subscriptions).count -gt 0)
        {
            Write-Host "#######################################################################"
            Write-Host "There are more subscription available:"

            $count = 0
            foreach ($subscription in $subscriptions) 
            {
                Write-Host "$($count): $($subscription.Name)"
                $count++
            }

            Write-Host "Please select the right subscription (insert the number)"
            Write-Host "#######################################################################"
            $result = Read-Host

            $selectedsubscription = $subscriptions[$result]
            Select-AzSubscription -SubscriptionObject $selectedsubscription
        }
        else 
        {
            $selectedsubscription = $subscriptions[0]
            Select-AzSubscription -SubscriptionObject $selectedsubscription
        }
    }
    catch {
        Write-Error "Error in select ressourcegroup section. Error message: $($_.Exception.Message)"
    }

    #endregion

    Write-Host "Get Access token"
    $accesstoken = Get-AzCachedAccessToken
    Remove-Module AzureRM*

#Create ResourceGroup if not exist
#---------------------------------------------------------------
    try 
    {            
        Write-Host "Create ResourceGroup $($resourcegroup) if not exist."

        $rg = Get-AzResourceGroup | Where-Object ResourceGroupName -EQ $resourcegroup
        if($null -eq $rg)
        {
            $rg = New-AzResourceGroup -Name $resourcegroup -Location $location
        }
    }
    catch {
        Write-Error "Error in create ressourcegroup section. Error message: $($_.Exception.Message)"
    }

#Create VNet, Subnet and PSE
#---------------------------------------------------------------
    try 
    {            
        Write-Host "Create virtual network"

        $delegation = New-AzDelegation -Name "PseDelegation" -ServiceName "Microsoft.Web/serverFarms"
        $subnetpse = New-AzVirtualNetworkSubnetConfig -AddressPrefix "10.0.1.0/24" -Name "Sub-PSE" `
                                                      -ServiceEndpoint Microsoft.Web,Microsoft.Sql,Microsoft.KeyVault `
                                                      -Delegation $delegation                                        

        $vnet = New-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rg.ResourceGroupName -Location $location `
                                     -AddressPrefix "10.0.0.0/16" -Subnet $subnetpse

        $subnetid = ($vnet.Subnets | Where-Object Name -EQ $subnetpse.Name).Id
    }
    catch {
        Write-Error "Error in create virtual network section. Error message: $($_.Exception.Message)"
    }

#Create SQL Server, Database and enable PSE
#---------------------------------------------------------------
    try 
    {            
        Write-Host "Create SQl server and database"
        $sqlserver = New-AzSqlServer -Location $location -ServerName $sqlservername -SqlAdministratorCredentials $sqlservercredential `
                                     -AssignIdentity -ResourceGroupName $resourcegroup        

        $sqldatabase = New-AzSqlDatabase -DatabaseName $sqldatabasename -ResourceGroupName $resourcegroup -ServerName $sqlserver.ServerName `
                                         -Edition GeneralPurpose -VCore 2 -ComputeGeneration Gen5 -ComputeModel Serverless 

        Write-Host "Enable PSE for SQL servere"
        $sqlvnet = New-AzSqlServerVirtualNetworkRule -ResourceGroupName $sqlserver.ResourceGroupName -ServerName $sqlserver.ServerName `
                                                     -VirtualNetworkRuleName "DemoPSERule" `
                                                     -VirtualNetworkSubnetId ($vnet.Subnets | Where-Object Name -eq $subnetpse.Name).Id

    }
    catch {
        Write-Error "Error in create SQL services section. Error message: $($_.Exception.Message)"                                                
    }

#Create AppServicePlan, AppService and enable PSE
#---------------------------------------------------------------
    try 
    {            
        Write-Host "Create AppServicePlan and AppService"
        $appsvcplan = New-AzAppServicePlan -ResourceGroupName $resourcegroup -Location $location -Name $appsvcplanname `
                                           -Tier Standard -NumberofWorkers 1 -WorkerSize Small

        
        $webapp = New-AzWebApp -Name $webappname -Location $location -ResourceGroupName $resourcegroup -AppServicePlan $appsvcplan.Name
        $webappidentity = Set-AzWebApp -Name $webapp.Name -ResourceGroupName $webapp.ResourceGroup -AssignIdentity $true        

        Write-Host "Enable PSE for AppService"
        $resourceId = "$($webapp.Id)/config/virtualNetwork"

        $url = "https://management.azure.com$resourceId" + "?api-version=2018-02-01"

        $payload = @{ id=$resourceId; location=$location;  properties=@{subnetResourceId=$subnetid; swiftSupported="true"} } | ConvertTo-Json
        $enableappsvcpseresponse = Invoke-RestMethod -Method Put -Uri $url -Headers @{ Authorization="Bearer $accesstoken"; "Content-Type"="application/json" } -Body $payload -Verbose -Debug         
    }
    catch {
        Write-Error "Error in create AppService services section. Error message: $($_.Exception.Message)"       
    }
    
#Create KeyVault
#---------------------------------------------------------------
    try 
    {        
        Write-Host "Create Azure KeyVault"
        $keyvault = New-AzKeyVault -Name $keyvaultname -ResourceGroupName $resourcegroup -Location $location 

        Write-Host "Add KeyVault Policy"
        Set-AzKeyVaultAccessPolicy -VaultName $keyvault.VaultName -ResourceGroupName $resourcegroup -ObjectId $webappidentity.Identity.PrincipalId -PermissionsToSecrets get,list

        $sqlpw= [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlservercredential.Password)
        $sqlpw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($sqlpw)

        $connectionstring = "Server=sqldemopse.database.windows.net;Initial Catalog=demopsedb;Persist Security Info=False;User `
                             ID=$($sqlservercredential.UserName);Password=$($sqlpw);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
                             | ConvertTo-SecureString -AsPlainText -Force

        Write-Host "Add KeyVault Secret"
        $keyvaultsectret = Set-AzKeyVaultSecret -Name $keyvaultsecretname -VaultName $keyvault.VaultName -SecretValue $connectionstring

        Write-Host "Enable PSE for KeyVault"
        Add-AzKeyVaultNetworkRule -VaultName $keyvault.VaultName -VirtualNetworkResourceId $subnetid
        Update-AzKeyVaultNetworkRuleSet -VaultName $keyvault.VaultName -DefaultAction Deny -Bypass None 

    }
    catch {
        Write-Error "Error in create KeyVault section. Error message: $($_.Exception.Message)"       
    }

#endregion
#######################################################################################################################
