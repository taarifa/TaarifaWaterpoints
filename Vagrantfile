# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "https://vagrantcloud.com/ubuntu/trusty64/version/1/provider/virtualbox.box"

  # Sync the TaarifaAPI repository
  config.vm.synced_folder "../TaarifaAPI", "/home/vagrant/TaarifaAPI"

  # Sync the TaarifaWaterpoints repository
  config.vm.synced_folder ".", "/home/vagrant/TaarifaWaterpoints"

  # Forward the default flask port
  config.vm.network "forwarded_port", guest: 5000, host: 5000

  # Forward the grunt development server port
  config.vm.network "forwarded_port", guest: 9000, host: 9000

  # Provision the VM
  config.vm.provision "shell", path: "install.sh", :privileged => false
  config.vm.provision "shell", path: "bootstrap.sh", :privileged => false
end
