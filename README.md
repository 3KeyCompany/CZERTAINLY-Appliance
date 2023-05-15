# CZERTAINLY Appliance Builder

Builder of [CZERTAINLY Appliance](https://docs.czertainly.com/docs/installation-guide/deployment/deployment-appliance/overview), if you are not interested in developement you should just [download](https://docs.czertainly.com/docs/installation-guide/deployment/deployment-appliance/overview#download-and-import-image) published Appliance image. This repository is ment for developers.

## Prerequisites

* a Debian based Linux system with **root access**  - tested on GNU Debian/Linux 11 (Bullseye). Root access is needed for `debbootstrap`, mounting qemu disk format, formating disk image - most of task is run as root.
* `git` for cloning this repo
* VirtualBox 7.0 (6.0 version doesn't have `--delete-all` option otherwise script should run)
* `qemu-img` and `qemu-nbd` from `qemu-utils`, complete Qemu installation isn't needed
* `debootstrap`
* `dosfstools` for creating FAT partition with EFI stuff

In short:
`apt install git virtualbox qemu-utils debbootstrap dosfstools`

## Building

```
git clone https://github.com/3KeyCompany/CZERTAINLY-Appliance.git
cd CZERTAINLY-Appliance
./build-appliance
```
Finished apliance is exported into file `tmp/czertainly-appliance-$APPLIANCEVERSION."%g%m%d.%H%M%S.ova`. The proces takes about 7 minutes on i7-6700 CPU @ 3.40GHz.

## Usage of the Appliance

Appliance comes with preconfigured Debian system. You need to initialiaze rke2 cluster and install CZERTAINLY. Please follow instructions from [offical documentation](https://docs.czertainly.com/docs/installation-guide/deployment/deployment-appliance/initialization).

## Tips for developers

By default Appliance builder uses parameters from [`vars/develop`](./vars/develop) you can make your own modifications to that file and pass it as first argument of the builder, for example:
```
sudo BUILD_PARAMS=vars/local bash ./build-appliance
```
Playbook for CZERTAINLY installation depends on following Ansible
roles:
  - [ansible-role-czertainly-branding](https://github.com/3KeyCompany/ansible-role-czertainly-branding)
  - [ansible-role-http-proxy](https://github.com/3KeyCompany/ansible-role-http-proxy)
  - [ansible-role-postgres](https://github.com/3KeyCompany/ansible-role-postgres)
  - [ansible-role-helm](https://github.com/3KeyCompany/ansible-role-helm)
  - [ansible-role-rke2](https://github.com/3KeyCompany/ansible-role-rke2)
  - [ansible-role-czertainly](https://github.com/3KeyCompany/ansible-role-czertainly)

they are provided by package [`czertainly-appliance-tools`](https://github.com/semik/CZERTAINLY-Appliance-Tools), without any git tracking informations. If you need to work on any of them, best option is to clone a repository of the role you need to work on into right place under `/etc/czertainly-ansible/roles`.

If you want to run Ansible playbooks by hand don't forget to set `ANSIBLE_CONFIG` to [right](https://github.com/semik/CZERTAINLY-Appliance-Tools/blob/main/usr/bin/czertainly-tui#L26) values. Typicaly you can run instalation command from menu of Text UI.

All Ansible roles have tags. You can run only parts you need to re-run to save your time. For example, when you want just reinstall czeratinly you can do:
```
kubectl delete ns czertainly
ANSIBLE_CONFIG=/etc/czertainly-ansible/ansible.cfg ansible-playbook /etc/czertainly-ansible/playbooks/czertainly.yml --tags czertainly --skip-tags czertainly_sleep10
```
## Tested compatibility of resulting OVA

* VirtualBox 6.1
* VirtualBox 7.0.4 / working environment
* VMPlayer 16.2.4
* VMPlayer 17.0.0

## Notes

Originaly was the appliance builder based on `preseed.cfg` file which offical way for customizing Debian instalation. It is [documented](https://www.debian.org/releases/stable/amd64/apbs02.en.html), but can be sometimes quite tricky to get it working correctly. Main problem with this aproach was that it required VT-x instructions, for full virtualization. That is not available in Ubuntu based GitHub runners. With some modifications it was possible run it on MacOS based runners, but building process was taking to long and often was terminated by GitHub after 6hours. Those modification for MacOS was replace `genisoimage`=>`mkisofs` and `isohybrid`=>`mkhybrid` which are luckyily dropin replacements.

Actual way of building the appliance is havily based on blog post [Building Debian VMs with debootstrap](https://blog.entek.org.uk/technology/2020/06/06/building-debian-vms-with-debootstrap.html). This way of building the appliance is much faster and it runs even on Ubuntu runners on GitHub.
