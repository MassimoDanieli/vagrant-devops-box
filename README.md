# DevOps box

A Vagrant box with the tools needed to do DevOps, on **Ubuntu 24.04 LTS**
(`bento/ubuntu-24.04`). Works on Intel/AMD and on **Apple Silicon** hosts:
the provisioning script detects amd64 or arm64.

## Tools included

| Tool | Source |
|---|---|
| Terraform, Packer | HashiCorp apt repository (latest) |
| kubectl | pkgs.k8s.io, minor release pinned in `scripts/install.sh` (`KUBECTL_MINOR`) |
| Skaffold | pinned release (`SKAFFOLD_VERSION`) |
| AWS CLI v2 | official installer |
| Ansible, Docker (+ Compose v2) | Ubuntu packages |
| Postman | snap, amd64 only |

An ed25519 key is created at `~/.ssh/mykey` for the `vagrant` user, who is in
the `docker` group.

## Usage

```bash
vagrant up            # VirtualBox, VMware or Parallels
vagrant ssh
```

On Apple Silicon use VirtualBox 7.1+, VMware Fusion or Parallels.

`scripts/install.sh` can be re-run (`vagrant provision`). CI provisions a clean
Ubuntu 24.04 container on amd64 and arm64 on every change and once a month.
