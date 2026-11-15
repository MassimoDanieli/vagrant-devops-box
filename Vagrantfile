# DevOps box: Ubuntu 24.04 LTS with Terraform, Packer, Ansible, Docker,
# kubectl, Skaffold and the AWS CLI. Works on Intel and Apple Silicon hosts
# (bento/ubuntu-24.04 ships amd64 and arm64 builds).
Vagrant.configure("2") do |config|
  config.vm.define "devops-box" do |devbox|
    devbox.vm.box = "bento/ubuntu-24.04"
    devbox.vm.hostname = "devops-box"
    # devbox.vm.network "private_network", ip: "192.168.56.9"

    devbox.vm.provision "shell", path: "scripts/install.sh"

    devbox.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 2
    end
    devbox.vm.provider "vmware_desktop" do |v|
      v.memory = 4096
      v.cpus = 2
    end
    devbox.vm.provider "parallels" do |v|
      v.memory = 4096
      v.cpus = 2
    end
  end
end
