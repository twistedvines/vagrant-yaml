# vagrant-puppetlab
###### Configurable Vagrant-based Puppet Lab

## Introduction
`vagrant-puppetlab` is a Vagrant project which facilitates a Puppet-driven environment controlled by a Puppet Enterprise master. `vagrant-puppetlab` uses a YAML-based VM configuration, which means that virtual machines can be defined in the YAML configuration provided to alter the environment to suit the user's requirements. Each VM specified can also be instantiated *n* times, which allows for powerful (and easy) multi-node Puppet environments.

Primarily, this Vagrant project is designed to be a local environment for studying the Puppet Professional course at [Linux Academy](https://linuxacademy.com); however, it can be used for any Puppet Environment.

## Usage
After this environment has been cloned, navigating to the directory and performing a `vagrant up` will spin-up the default environment: at current, this consists of:
- a `CentOS` Puppet Master running the latest version of Puppet Enterprise;
- a `CentOS` Puppet Agent installed with the Puppet Enterprise agent;
- a `Debian` Puppet Agent installed with the Puppet Enterprise agent;
- an `Ubuntu` Puppet Agent installed with the Puppet Enterprise agent.

To halt the environment, simply use `vagrant halt`.

To destroy the environment, use `vagrant destroy -f`.

For more information on Vagrant, read the [documentation](https://vagrantup.com/docs/).

To browse the Puppet Master's management site, use `vagrant landrush ls` to find the Puppet Master's IP address, then navigate to the IP address in your browser using `https`. Ignore the self-signed certificate and use `admin` as the username and `puppet64` as the password.

At present, every node uses `vagrant:vagrant` for login credentials.

## Requirements
### System
The environment can be quite resource-intensive for modest systems: the master itself, by default, uses 4GB of RAM and 2 vCPUs. Each agent is configured to use 1GB of RAM and 1 vCPU. This can all be configured using the supplied YAML configuration, however.

If you're considering running this environment using its default configuration, I would recommend:

|                 | GNU/Linux | OSX  | Windows |
|-----------------|-----------|------|---------|
| **Cores (Threads)** | 4         | 4    | 4       |
| **Memory**          | 12GB      | 12GB | 16GB    |
| **Disk Space**      | 6GB       | 6GB  | 6GB     |



### Software
To run this environment, you will need:
- [Vagrant](https://vagrantup.com);
- The following Vagrant plugins:
  - `vagrant-vbguest`, for installing the latest version of Virtualbox Guest Additions on the `centos-master` VM: this facilitates the sharing of the `/puppet_code` directory between host and guest - more information can be found on the [VBGuest GitHub Repository](https://github.com/dotless-de/vagrant-vbguest);
  - `vagrant-landrush`, for facilitating DNS requests on the `172.28.128.0/24` range. `landrush` also has the side-effect of overriding the inbuilt VirtualBox DNS server at `10.0.2.2` and proxies DNS through to a version of `dnsmasq` bound to port `10053` on the host. For more information, consult the [Landrush GitHub Repository](https://github.com/vagrant-landrush/landrush).

  ## Notes

**You cannot use the local-provisioning feature if you are running Windows - Cygwin may work but this is untested. I'd recommend using a *real* operating system ;)**

  Enjoy this environment! it was fun to Vagrant-ise. If you can think of any improvements, feel free to fork this repository off and work on them to submit for a merge request - or, alternatively, you can raise an issue.
