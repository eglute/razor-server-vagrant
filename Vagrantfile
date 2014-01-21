Vagrant.configure("2") do |config|  
  config.vm.box = "precise_fusion"
  
  # vagrant box add precise_fusion http://files.vagrantup.com/precise64_vmware.box
  
  
  config.vm.provider :vmware_fusion do |v|    
   #v.vm.network "private_network", ip: "172.16.2.137"
   v.vmx["memsize"] = "1024"
   v.vmx["numvcpus"] = "1"   
  end
  
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end
  
  config.vm.network "private_network", ip: "172.16.2.137"
  #config.vm.network "private_network", ip: "172.16.1.138", virtualbox__intnet: "mynetwork"
  config.vm.provision "shell", path: "provision.sh", :args =>"172.16.2.137 172.16.2.150 172.16.2.255" 
                  
end
