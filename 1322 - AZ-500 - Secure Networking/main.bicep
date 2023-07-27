param location string = 'eastus'
param hubVNetName string = 'vnet-hub'
param spokeVNetName string = 'vnet-spoke'
param hqVNetName string = 'vnet-hq'
param hubSubnetName string = 'default'
param spokeSubnetName string = 'default'
param hqSubnetName string = 'default'
param hubVNetAddressPrefix string = '10.0.0.0/16'
param spokeVNetAddressPrefix string = '10.1.0.0/16'
param hqVNetAddressPrefix string = '10.2.0.0/16'
param hubSubnetAddressPrefix string = '10.0.1.0/24'
param spokeSubnetAddressPrefix string = '10.1.1.0/24'
param hqSubnetAddressPrefix string = '10.2.1.0/24'
param hubGatewaySubnetPrefix string = '10.0.2.0/24'
param hqGatewaySubnetPrefix string = '10.2.2.0/24'
param hubBastionSubnetPrefix string = '10.0.3.0/24'
param hqBastionSubnetPrefix string = '10.2.3.0/24'
param azureFirewallSubnetPrefix string = '10.0.4.0/24'
param vmSize string = 'Standard_D2s_v3'
param adminUsername string = 'azureuser'
@secure()
param adminPassword string
param vmName string = 'vm'
param vmPublisher string = 'Canonical'
param vmOffer string = '0001-com-ubuntu-server-focal'
param vmSku string = '20_04-lts-gen2'
param vmVersion string = 'latest'
param hubBastionName string = 'bastion-hub'
param hqBastionName string = 'bastion-hq'
param hubBastionPublicIPName string = 'pip-bastion-hub'
param hqBastionPublicIPName string = 'pip-bastion-hq'
param hubVNetGatewayName string = 'vng-hub'
param hqVNetGatewayName string = 'vng-hq'
param hubVNetGatewayPublicIPName string = 'pip-hub-vng'
param hqVNetGatewayPublicIPName string = 'pip-hq-vng'
param hubLocalNetworkGatewayName string = 'lng-hub'
param hqLocalNetworkGatewayName string = 'lng-hq'
@secure()
param vpnSharedKey string
param hubFirewallPublicIPName string = 'pip-fw-hub'
param hubFirewallName string = 'fw-hub'
param mainRouteTableName string = 'rt-main'

// Network Security Groups
resource hubNSG 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'nsg-hub'
  location: location
}

resource spokeNSG 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'nsg-spoke'
  location: location
}

resource hqNSG 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'nsg-hq'
  location: location
}

// Virtual Networks
resource hubVNet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: hubVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: hubSubnetName
        properties: {
          addressPrefix: hubSubnetAddressPrefix
          networkSecurityGroup: {
            id: hubNSG.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: hubGatewaySubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: hubBastionSubnetPrefix
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: azureFirewallSubnetPrefix
        }
      }
    ]
  }
}

resource spokeVNet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: spokeVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: spokeSubnetName
        properties: {
          addressPrefix: spokeSubnetAddressPrefix
          networkSecurityGroup: {
            id: spokeNSG.id
          }
        }
      }
    ]
  }
}

resource hqVNet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: hqVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hqVNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: hqSubnetName
        properties: {
          addressPrefix: hqSubnetAddressPrefix
          networkSecurityGroup: {
            id: hqNSG.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: hqGatewaySubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: hqBastionSubnetPrefix
        }
      }
    ]
  }
}

// VNet Peerings
resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-02-01' = {
  parent: hubVNet
  name: 'hubToSpoke'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVNet.id
    }
    allowVirtualNetworkAccess: true
  }
}

resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-02-01' = {
  parent: spokeVNet
  name: 'spokeToHub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVNet.id
    }
    allowVirtualNetworkAccess: true
  }
}

// Network Interfaces
resource hubNic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmName}-hub-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubVNet.id}/subnets/${hubSubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource spokeNic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmName}-spoke-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${spokeVNet.id}/subnets/${spokeSubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource hqNic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmName}-hq-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hqVNet.id}/subnets/${hqSubnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// VMs
resource hubVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: '${vmName}-hub'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmPublisher
        offer: vmOffer
        sku: vmSku
        version: vmVersion
      }
    }
    osProfile: {
      computerName: '${vmName}-hub'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: hubNic.id
        }
      ]
    }
  }
}

resource spokeVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: '${vmName}-spoke'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmPublisher
        offer: vmOffer
        sku: vmSku
        version: vmVersion
      }
    }
    osProfile: {
      computerName: '${vmName}-spoke'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: spokeNic.id
        }
      ]
    }
  }
}

resource hqVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: '${vmName}-hq'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmPublisher
        offer: vmOffer
        sku: vmSku
        version: vmVersion
      }
    }
    osProfile: {
      computerName: '${vmName}-hq'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: hqNic.id
        }
      ]
    }
  }
}

// Azure Bastions Public IPs
resource hubBastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: hubBastionPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource hqBastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: hqBastionPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Azure Bastion Hosts
resource hubBastionHost 'Microsoft.Network/bastionHosts@2023-02-01' = {
  name: hubBastionName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '${hubVNet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: hubBastionPublicIP.id
          }
        }
      }
    ]
  }
}

resource hqBastionHost 'Microsoft.Network/bastionHosts@2023-02-01' = {
  name: hqBastionName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '${hqVNet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: hqBastionPublicIP.id
          }
        }
      }
    ]
  }
}

// VNet Gateways Public IPs
resource hubVNetGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: hubVNetGatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource hqVNetGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: hqVNetGatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// VNet Gateways
resource hubVNetGateway 'Microsoft.Network/virtualNetworkGateways@2023-02-01' = {
  name: hubVNetGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: 65514
    }
    activeActive: false
    ipConfigurations: [
      {
        name: 'IPConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${hubVNet.id}/subnets/GatewaySubnet'
          }
          publicIPAddress: {
            id: hubVNetGatewayPublicIP.id
          }
        }
      }
    ]
  }
}

resource hqVNetGateway 'Microsoft.Network/virtualNetworkGateways@2023-02-01' = {
  name: hqVNetGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: 65516
    }
    activeActive: false
    ipConfigurations: [
      {
        name: 'IPConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${hqVNet.id}/subnets/GatewaySubnet'
          }
          publicIPAddress: {
            id: hqVNetGatewayPublicIP.id
          }
        }
      }
    ]
  }
}

// Local Network Gateways
resource hubLocalNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-02-01' = {
  name: hubLocalNetworkGatewayName
  location: location
  properties: {
    bgpSettings: {
      asn: hubVNetGateway.properties.bgpSettings.asn
      bgpPeeringAddress: hubVNetGateway.properties.bgpSettings.bgpPeeringAddress
    }
    gatewayIpAddress: hubVNetGatewayPublicIP.properties.ipAddress
  }
}

resource hqLocalNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-02-01' = {
  name: hqLocalNetworkGatewayName
  location: location
  properties: {
    bgpSettings: {
      asn: hqVNetGateway.properties.bgpSettings.asn
      bgpPeeringAddress: hqVNetGateway.properties.bgpSettings.bgpPeeringAddress
    }
    gatewayIpAddress: hqVNetGatewayPublicIP.properties.ipAddress
  }
}

// Connection(s)
resource hub_to_hq_conn 'Microsoft.Network/connections@2023-02-01' = {
  name: 'hub-to-hq-conn'
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: hubVNetGateway.id
    }
    localNetworkGateway2: {
      id: hqLocalNetworkGateway.id
    }
    connectionType: 'IPsec'
    enableBgp: true
    connectionProtocol: 'IKEv2'
    sharedKey: vpnSharedKey
  }
}

resource hq_to_hub_conn 'Microsoft.Network/connections@2023-02-01' = {
  name: 'hq-to-hub-conn'
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: hqVNetGateway.id
    }
    localNetworkGateway2: {
      id: hubLocalNetworkGateway.id
    }
    connectionType: 'IPsec'
    enableBgp: true
    connectionProtocol: 'IKEv2'
    sharedKey: vpnSharedKey
  }
}

// Firewall Public IP(s)
resource hubFirewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: hubFirewallPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Firewall(s)
resource hubFirewall 'Microsoft.Network/azureFirewalls@2023-02-01' = {
  name: hubFirewallName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConf'
        properties: {
          publicIPAddress: {
            id: hubFirewallPublicIP.id
          }
          subnet: {
            id: '${hubVNet.id}/subnets/AzureFirewallSubnet'
          }
        }
      }
    ]
    sku: {
      tier: 'Standard'
    }
  }
  zones: [
    '1'
  ]
}

// Route Table(s)
resource mainRouteTable 'Microsoft.Network/routeTables@2023-02-01' = {
  name: mainRouteTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

// Outputs
