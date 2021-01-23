#region PS CloudShell deployment

    $resourcelocation = "westeurope"

    #Create azure resourcegroup
    #region
        $rgname = "rg-testyts-10"

        $rgstate = New-AzResourceGroup -name $rgname -Location $resourcelocation -Tag @{DemoFor="YTSession10"; Details="Demo RG for YoutTube Session 10"; Owner="Hannes Lagler-Gruener"}

        if($rgstate.ProvisioningState -eq "Succeeded")
        {
            Write-Host $rgstate.ProvisioningState -ForegroundColor Green
        }

    #endregion


    #Creation VNET:
    #region
        $vnetname = "demo-vnet-yts10"
        $subname = "backend"
        $VnetAddressPrefix = "10.0.0.0/16"
        $SubnetAddressPrefix = "10.0.0.0/24"

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subname -AddressPrefix $SubnetAddressPrefix
        $Vnet = New-AzVirtualNetwork -Name $vnetname `
                                    -ResourceGroupName $rgname `
                                    -Location $resourcelocation `
                                    -AddressPrefix $VnetAddressPrefix `
                                    -Subnet $subnet

        if($Vnet.ProvisioningState -eq "Succeeded")
        {
            Write-Host $rgstate.ProvisioningState -ForegroundColor Green
        }
    #endregion

    #Create VM:
    #region

        $vmcredential = Get-Credential
        $ComputerName = "demo-yts-10-ps"
        $VMName = "demo-yts-10-ps"
        #To get VM Sizes enter: Get-AzVMSize -Location WestEurope
        $VMSize = "Standard_B2ms"
        $NICName = $("$VMName-nic")

        $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $rgname -Location $resourcelocation -SubnetId $Vnet.Subnets[0].Id

        $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
        $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $vmcredential -ProvisionVMAgent -EnableAutoUpdate
        $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id

        #Get Image Information:
        # $publisher = Get-AzVMImagePublisher -Location WestEurope
        # for windows server you can find in the $publisher variable "MicrosoftWindowsServer"

        # $offer = Get-AzVMImageOffer -Location WestEurope -Publisher MicrosoftWindowsServer
        # for windows server you can find in the $offer variable "WindowsServer"

        # $skus = Get-AzVMImageSKU -Location WestEurope -Publisher MicrosoftWindowsServer -Offer WindowsServer
        # all skus are available in the $skus variable
        $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter-smalldisk' -Version latest

        New-AzVM -ResourceGroupName $rgname -Location $resourcelocation -VM $VirtualMachine -Verbose

    #endregion

    #Cleanup
    #region
        Remove-AzResourceGroup -Name $rgname -Force
    #endregion

#endregion

#region PS CloudShell change to HomeDrive

cd /home/admin/clouddrive  
mkdir "test1234"

dir
ls

rmdir "test1234"

#endregion

#region PS CloudShell use Azure drive

cd Azure:
dir

cd "Laglerh-DevTest-MSDN"
cd ./ResourceGroups

dir

Get-AzVM

cd ~

#endregion