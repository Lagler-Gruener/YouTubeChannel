@allowed([
  'NetworkOnly'
  'FullDeployment'
])
@description('NetworkOnly deployes the network componentes and the FullDeployment the whole solution')
param DeploymentType string = 'FullDeployment'

@minLength(5)
@maxLength(15)
@description('Minimum 5 chars, maximum 15 chars arer allowed!')
param VMName string = 'bicep-vm01'

var virtualNetworks_vnetwe_name = 'bicep-vnet-${uniqueString(toLower(resourceGroup().id))}'
var networkSecurityGroups_NSGFrontendWE_name = 'bicep-nsg-${uniqueString(toLower(resourceGroup().id))}'
var publicIPAddresses_demovmwe_ip_name = 'bicep-pip-${uniqueString(toLower(resourceGroup().id))}'
var nicname_vm_we = 'bicep-nic-${uniqueString(toLower(resourceGroup().id))}'

var dscurl = '<Define the DSC URL>'


//Get existing resource
//##############################################################################
resource SecredDemoKV 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'armdemo'
  scope: resourceGroup(subscription().subscriptionId, resourceGroup().name)
}
//##############################################################################



resource NSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name:networkSecurityGroups_NSGFrontendWE_name
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name:'HTTP-Allow'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'	
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []

        }
      }
    ]
  }
}

resource VNET 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name:virtualNetworks_vnetwe_name
  location:resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Frontend'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: NSG.id
          }
          serviceEndpoints: []
          delegations: []
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource PIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name:publicIPAddresses_demovmwe_ip_name
  location:resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicIPAddresses_demovmwe_ip_name
    }
  }
}

resource VMNIC 'Microsoft.Network/networkInterfaces@2021-02-01' = if (DeploymentType == 'FullDeployment') {
  name:nicname_vm_we
  location:resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${VNET.id}/subnets/Frontend'
          }
          publicIPAddress: {
            id: PIP.id
          }
        }
      }
    ]
  }
}

module deployvm 'deployvm.bicep' = {
  name: 'bicep-deployvmwithsecret'
  params: {
    nicid: VMNIC.id
    VMName: VMName
    adminLogin: 'adminuser'
    adminPassword: SecredDemoKV.getSecret('VMadminPassword')    
    DSCurl: dscurl
    DSCKey: SecredDemoKV.getSecret('dsckey')
  }
}


