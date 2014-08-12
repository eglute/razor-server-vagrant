Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"

  # Virtualbox
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end

  # VMware Fusion / Workstation
  config.vm.provider "vmware_fusion" do |vmware, override|

    # Fusion Performance Hacks
    vmware.vmx["logging"] = "FALSE"
    vmware.vmx["MemTrimRate"] = "0"
    vmware.vmx["MemAllowAutoScaleDown"] = "FALSE"
    vmware.vmx["mainMem.backing"] = "swap"
    vmware.vmx["sched.mem.pshare.enable"] = "FALSE"
    vmware.vmx["snapshot.disabled"] = "TRUE"
    vmware.vmx["isolation.tools.unity.disable"] = "TRUE"
    vmware.vmx["unity.allowCompostingInGuest"] = "FALSE"
    vmware.vmx["unity.enableLaunchMenu"] = "FALSE"
    vmware.vmx["unity.showBadges"] = "FALSE"
    vmware.vmx["unity.showBorders"] = "FALSE"
    vmware.vmx["unity.wasCapable"] = "FALSE"

    # Memory:
    vmware.vmx["memsize"] = "1024"
    vmware.vmx["numvcpus"] = "1"   

  end

  config.vm.network "private_network", ip: "172.16.2.137"
  config.vm.provision "shell", path: "provision.sh", :args =>"172.16.2.137 172.16.2.150 172.16.2.255" 
                  
end
