  <#
    .SYNOPSIS
        This script create an storage account and add to an existing ADDS
        
    .DESCRIPTION
        1.) Download the required module from website https://github.com/Azure-Samples/azure-files-samples/releases
        2.) Unzip the module and install it
        3.) Install the Az Modules
        4.) Create an storage account
        5.) Create the File Storage
        6.) Join the Filestorage to the local AD



    .EXAMPLE


    .NOTES                                    
        Prerequisits:
            - An Azure Active Directory Domain
            - Or an Active Directory Domain
            - The users are synced to the Cloud with Azure AD Conenct or Azure AD cloud sync
            - The Users are assign with one of the following permissions to the Storage account
                - Storage File Data SMB Share Reader 
                - Storage File Data SMB Share Contributor 
                - Storage File Data SMB Share Elevated Contributor
#>


[CmdletBinding()]
param (
    [parameter (Mandatory=$true)]
    $SubscriptionId,
    [parameter (Mandatory=$true)]
    $ResourceGroupName,
    [parameter (Mandatory=$true)]
    $StorageAccountName
)

#Set execution Policy
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

#Download the File from Github
    mkdir C:\temp
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.3/AzFilesHybrid.zip -OutFile C:\temp\AzFilesHybrid.zip

#Unzio File to C:\temp
    Expand-Archive C:\temp\AzFilesHybrid.zip -DestinationPath C:\temp\AzFilesHybrid

#Install AZ Modules
    Install-Module Az

#Execute the Script to install the Module
    cd C:\temp\AzFilesHybrid
    .\CopyToPSPath.ps1
   

#Import module
    Import-Module -Name AzFilesHybrid

#Connect to Azure
    Connect-AzAccount
    Select-AzSubscription -SubscriptionId $SubscriptionId 

#Create Azure FileStorage
    $result = New-AzStorageAccount -ResourceGroupName $ResourceGroupName `
                                   -AccountName $StorageAccountName `
                                   -Location "WestEurope" `
                                   -SkuName "Standard_LRS" `
                                   -Kind StorageV2      
                     
#Create a new Fileshare                 
    New-AzStorageShare -Name "fileshare01" -Context $result.Context

#Join Storage Account to ADDS Domain

    Join-AzStorageAccountForAuth `
            -ResourceGroupName $ResourceGroupName `
            -StorageAccountName $StorageAccountName `
            -DomainAccountType "ComputerAccount" `
            -EncryptionType "AES256"

    Update-AzStorageAccountAuthForAES256 -ResourceGroupName $ResourceGroupName `
                                         -StorageAccountName $StorageAccountName




#Assign the RBAC Permission to the Storage Account and mount the storage
