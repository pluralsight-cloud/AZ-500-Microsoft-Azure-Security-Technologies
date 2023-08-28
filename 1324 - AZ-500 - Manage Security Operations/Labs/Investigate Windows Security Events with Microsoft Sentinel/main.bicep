var vmSize = 'Standard_B2ms'
var vmName = 'lab-VM'
var sku = '2019-Datacenter'
var uniqueDnsLabelPrefix = 'store${uniqueString(resourceGroup().id)}'
var location = resourceGroup().location
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'default'
var subnet1Prefix = '10.0.0.0/24'
var nicName = 'lab-VM-NIC'
var publicIPAddressName = 'lab-VM-PIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName = 'lab-VM-VNET'
var networkSecurityGroupName = 'lab-VM-NSG'
var vnetID = virtualNetwork.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var workspaceName = 'LogAnalyticsWorkspace'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'rdp_rule'
        properties: {
          description: 'Locks inbound down to rdp default port 3389.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 123
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: uniqueDnsLabelPrefix
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: sku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource workspace 'microsoft.operationalinsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  dependsOn: [
    vm
  ]
}

resource vmCSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm
  name: '${vmName}-cse'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/pluralsight-cloud/AZ-500-Microsoft-Azure-Security-Technologies/main/1324%20-%20AZ-500%20-%20Manage%20Security%20Operations/Labs/Investigate%20Windows%20Security%20Events%20with%20Microsoft%20Sentinel/Deploy-Server.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Deploy-Server.ps1'
    }
  }
}

output vmsWithLogin array = [
  {
    name: 'lab-VM'
    showPrivateIp: false
    showPublicIp: true
    showFqdn: false
  }
]
