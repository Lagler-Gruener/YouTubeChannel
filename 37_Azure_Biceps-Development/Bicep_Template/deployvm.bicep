param VMName string
param adminLogin string
@secure()
param adminPassword string
param nicid string

param DSCurl string

@secure()
param DSCKey string

var configurationModeFrequencyMins = '15'
var refreshFrequencyMins = '30'

resource VM 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: VMName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      osDisk: {
        name: '${toLower(VMName)}osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicid
        }
      ]
    }
    osProfile: {
      computerName: VMName
      adminUsername: adminLogin
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }    
  }
  resource Identifier 'extensions' = {
    name: 'Microsoft.Powershell.DSC'
    location: resourceGroup().location
    properties: {
      publisher:'Microsoft.Powershell'
      type:'DSC'
      typeHandlerVersion:'2.75'
      autoUpgradeMinorVersion: true
      protectedSettings: {
        Items: {
          registrationKeyPrivate: DSCKey
        }
      }
      settings: {
        'modulesUrl': ''
          Properties: [
            {
              Name: 'RegistrationKey'
              Value: {
                UserName: 'PLACEHOLDER_DONOTUSE'
                Password: 'PrivateSettingsRef:registrationKeyPrivate'
              }
              TypeName: 'System.Management.Automation.PSCredential'
            }
            {
              Name: 'RegistrationUrl'
              Value: DSCurl
              TypeName: 'System.String'
            }
            {
              Name: 'NodeConfigurationName'
              Value: 'deployiis.WebServerConfig'
              TypeName: 'System.String'
            }
            {
              Name: 'ConfigurationMode'
              Value: 'ApplyandAutoCorrect'
              TypeName: 'System.String'
            }
            {
              Name: 'RebootNodeIfNeeded'
              Value: true
              TypeName: 'System.Boolean'
            }
            {
              Name: 'ActionAfterReboot'
              Value: 'ContinueConfiguration'
              TypeName: 'System.String'
            }
            {
              Name: 'ConfigurationModeFrequencyMins'
              Value: configurationModeFrequencyMins
              TypeName: 'System.Int32'
            }
            {
              Name: 'RefreshFrequencyMins'
              Value: refreshFrequencyMins
              TypeName: 'System.Int32'
            }
          ]
      }
    }
  }
}
