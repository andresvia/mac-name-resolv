My struggle with MacOS name resolving
=====================================

Some of the affirmations stated here come from day-to-day experience with
MacOS maybe some information is missing or wrongly assumed particularly about
how certain software behaves. If you have an amend to make please open an issue
or send a pull request.

 - Trying to understand how DNS works on a MacOS
   - MacOS uses not only `resolv.conf` (as in many other \*nix-es)
     - BTW `resolv.conf` is only used by few \*nix classic utilities
       like `nslookup` however all other known applications, including
       but not limited to, graphical apps and even `ping` command, use
       the POSIX system call, [gethostbyname] [1].
     - An exception to this are utilities like [Vagrant] [2] and
       [docker-machine] [3], those (apparently) will read the `resolv.conf`
       file and propagate its settings to the managed virtual machines during
       boot.
   - MacOS manages `resolv.conf` and determines the behavior of `gethostbyname`
       according to system settings (set by `scutil` and graphical
       configuration tools), also which networks are currently connected;
       physical ethernet, Wi-Fi APs, VPNs; values received from DHCP on those
       networks, and values hinted by VPN clients are used to set the file and
       determine the syscall behavior. The `resolv.conf` file is not
       immediately updated, however `gethostbyname` always respond according to
       settings and also the domain part of of the name, example, `scutil`
       contains sections for `*.domain1.net`, `*.domain2.net`, etc.
   - While this MacOS convenience may be useful for regular users, it
     become a hassle and a source of frustration for technical users, which
     are accustomed to change DNS settings in a single place and also expect
     that all utilities across the whole operative system respond the same
     to a simple name query no matter the program or client.

`get_dns.sh` and `set_dns.sh` will respectively query and set the DNS across
all the known places on a MacOS system, except `resolv.conf` because this one
is updated eventually automatically by the OS itself.

Tested on El Capitan.

Notes
-----

 - The utils don't know the name of your Docker machine, by default uses one
called "boot2docker" set `DEFAULT_DOCKER_MACHINE_NAME` in your `~/.profile`
to change the default behavior.

 - I expect your user can sudo `scutil` and `networksetup` to avoid asking
password add this to your sudoers.

```
<YOURNAME> ALL=(ALL)	NOPASSWD: NOPASSWD: /usr/sbin/scutil, \
    NOPASSWD: /usr/sbin/networksetup
```

 - If `dlite` executable is found, `dlite` is assumed to be running.

Example
-------

Getting consistently the same DNS server "everywhere".

    macs-Mac-mini:~ andres$ set_dns.sh 8.8.8.8
    macs-Mac-mini:~ andres$ get_dns.sh
    -------------------
    network_service_dns
    -------------------
    <dictionary> {
      ServerAddresses : <array> {
        0 : 8.8.8.8
      }
    }
    <dictionary> {
      ServerAddresses : <array> {
        0 : 8.8.8.8
      }
    }
    <dictionary> {
      ServerAddresses : <array> {
        0 : 8.8.8.8
      }
    }
    -----------
    resolv.conf
    -----------
    8.8.8.8
    --------------
    docker -dlite-
    --------------
    DhyveOS version 2.0.0
    Docker version 1.9.1, build a34a1d5
    8.8.8.8
    --------------
    docker-machine
    --------------
    Boot2Docker version 1.9.0, build master : 16e4a2a - Tue Nov  3 19:49:22 UTC 2015
    Docker version 1.9.0, build 76d6bc9
    8.8.8.8
    -----------------------------
    networksetup ethernet - wi-fi
    -----------------------------
    8.8.8.8
    8.8.8.8

[1]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/gethostbyname.3.html
[2]: https://www.vagrantup.com
[3]: https://docs.docker.com/machine/
