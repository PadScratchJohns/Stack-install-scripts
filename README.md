A place for shell scrips for installing some software easily.

So far: 
- CoTURN Ubuntu apt version (4.5.1) or source build with prometheus support (4.5.2) Debian repo has 4.5.2 as standard now.
- FreeSWITCH Debian (apt latest - needs signalwire account and token) or - FreeSWITCH source build (v1.10.10 but can be changed.)
- Homer apt version (7.7) auto selects from Ubuntu or Debian
- Kamailio apt version (5.7) or source build (read the script as this is for any modules not in the apt repo)
- RTPengine apt stable version (10.5) for Debian - no way to do this in 20.04/22.04 due to iptables-dev not being in focal/jammy repo's - support is coming for 23.10/24.04 so will update once they are in and tested. (Using a ppa currently for this.)

Setup for Ubuntu 20.04/22.04 mainly but with support for Debian 10/11/12 as applicable.

How to:
git clone and extract to desired location. Add the script to /tmp
chmod +x /tmp/script_name.sh 
./tmp/script_name.sh 

You should be root for this. 

The script has some interactive parts to ask about rebooting and versions etc. 

This is documented in the scripts so have a look if unsure.
