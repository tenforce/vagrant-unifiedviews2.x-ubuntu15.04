# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # switch off the vbguest updates since we are running the latest.
  # config.vbguest.auto_update = false
  # config.vbguest.no_remote = true  
  
  # This will attempt to cache downloaded files (only if plugin is
  # present).
  if Vagrant.has_plugin?("vagrant-cachier")
     config.cache.scope = :box
  end

  config.vm.box = "boxcutter/ubuntu1504"
  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision :shell, path: "bootstrap.sh", binary: false

  # Default provider setup
  config.vm.provider "virtualbox" do |vb|
      vb.name = "VagrantUnifiedView2.x-Ubuntu15.04"
      vb.gui = true
      vb.customize ["modifyvm", :id, "--memory", 4096]
      vb.customize ["modifyvm", :id, "--vram", 64]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
      # Customize the amount of memory on the VM:
      vb.memory = "4096"
  end

  # Only on linux boxes with libvirt installed
  #    vagrant up --provider=libvirt
  config.vm.provider :libvirt do |libvirt|
      libvirt.host = "VagrantUnifiedView2.x-Ubuntu15.04"
  end
end
