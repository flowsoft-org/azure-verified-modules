param resourceLocation string = 'italynorth'

param regionName string = 'global'

param addressPrefixHub string = '10.0.0.0/24' 
param addressPrefixBastion string = '10.0.0.128/29'
param addressPrefixApplicationGateway string = '10.0.0.192/26'
param applicationGatewayIpAdress string = '10.0.0.196'
param addressPrefixAKSDNS string = '10.0.0.10'
param addressPrefixAKS string = '10.0.0.0/26'
param adressPrefixUser string = '10.0.0.64/29'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-network-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixHub
    ]
    name: 'vnet-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'ApplicationGatewaySubnet'
        addressPrefix: addressPrefixApplicationGateway
      }
      {
        name: 'UserSubnet'
        addressPrefix: adressPrefixUser
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: addressPrefixBastion
        // No route table can be attached
      }
      {
        name: 'AKSSubnet'
        addressPrefix: addressPrefixAKS
        // No route table can be attached
      }
    ]
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}Bastion'
  params: {
    // Required parameters
    name: '${regionName}Bastion'
    vNetId: virtualNetwork.outputs.resourceId
    scaleUnits: 1 // testing reducing costs
    skuName: 'Basic' // testing reducing costs
    location: resourceLocation
  }
}

module virtualMachineA 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-vm-a'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: '${regionName}-vm-a'
    location: resourceLocation
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[1]
          }
        ]
        nicSuffix: '-nic-01'
        enablePublicIP: false
        enableAcceleratedNetworking: false // Accelerated Networking is not supported for B1s
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: '32'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_B1s'
    // encryptionAtHost: true // default true if not working use 'az feature register --name EncryptionAtHost --namespace Microsoft.Compute'
    // Non-required parameters
    disablePasswordAuthentication: true
    publicKeys: [
      {
        keyData: loadTextContent('../id_rsa.pub')
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.6.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-aks-private'
  params: {
    // Required parameters
    name: '${regionName}-private-aks'
    primaryAgentPoolProfiles: [
      {
        availabilityZones: [
          3
        ]
        count: 1
        enableAutoScaling: true
        maxCount: 3
        maxPods: 30
        minCount: 1
        mode: 'System'
        name: 'systempool'
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        osDiskSizeGB: 0
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_DS2_v2'
        vnetSubnetResourceId: virtualNetwork.outputs.subnetResourceIds[3]
      }
    ]
    // Non-required parameters
    aadProfile: {
      aadProfileEnableAzureRBAC: true
      aadProfileManaged: true
    }
    managedIdentities: {
      systemAssigned: true
    }
    dnsServiceIP: '10.200.0.10'
    enablePrivateCluster: true
    networkPlugin: 'azure'
    privateDNSZone: 'none'
    enablePrivateClusterPublicFQDN: true
    serviceCidr: '10.200.0.0/24'
    skuTier: 'Standard'
  }
}


output networkIdsAndRegions array = [
  {
    networkid: virtualNetwork.outputs.resourceId
    region: regionName
  }
]
