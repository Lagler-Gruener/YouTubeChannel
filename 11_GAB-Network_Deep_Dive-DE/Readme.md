## This is the content to the YouTube Video 1_Using Azure Cloudshell
You can find the YouTube video [here](https://www.youtube.com/watch?v=Npr9_CmTuGc&t=15s)

The following content is available:
* PowerShell deployment script
* Azure WebApp source
* Azure SQLTable schema/data

### Prerequisites
The script and architecture had the following prerequisites:

* An active Azure subscription
* Latest Powershell Az Modules installed
* Latest Powershell AzureRM.Profile installed
* Owner permission in your Azure Subscription

### Installation
All prerequisits are in place, so we can start with the implementation.

Please start the script.
First you have to insert the required admin account and password for your Azure SQL Database.
The input looks like:

    #######################################################################
    Windows PowerShell credential request.
    Please enter sql server credential
    User: sampleuser
    Password for user sampleuser: ************
    #######################################################################

Okay after that, you have to login into your Azure Tenant. Important, you need an active subscription and Owner permission.

When the login was successfull and you have more than one subscription bound, you have to select the right one.
The output looks like:

    #######################################################################
    There are more subscription available:
    0: Microsoft Azure Subs1
    1: Microsoft Azure Subs2
    Please select the right subscription (insert the number)
    #######################################################################

If everything was fine, the script start with the deployment. If there is an error in any section, the script will stop.
At the end there are the following ressources deployed:

* Azure Virtual Network with the following settings:
    * Adress Space: 10.0.0.0/16
    * Subnet Sub-PSE with Adress Space: 10.0.1.0/24
    * Service Endpoint:
        * Microsoft.Web
        * Microsoft.Sql
        * Microsoft.KeyVault
    enabled.
    * Network delegation Microsoft.Web/serverFarms enabled
* Azure SQL Server with the following settings:
    * Size: 2vCores, Gen5 in serverless mode
    * Private Service Endpoint integrated
    * Managed Identity assign
* Azure AppService Plan with one AppService
    * Tier: Standard
    * NumberofWorkers: 1
    * WorkerSize: Small
    * Managed Identity assigned
    * Private Service Endpoint integrated
* Azure KeyVault
    * Private Service Endpoint integrated
    * One secred with the Azure SQL connection string

### Authors
Hannes Lagler-Gruener

### Future Versions
* Auto source code deployment.
* Auto sql table deployment

