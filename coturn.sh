#!/bin/bash

sudo apt-get install -y lsb-release
# No promtheus support in Ubuntu 20.04 apt version 4.5.1 - for this you need >= 4.5.2
# For 4.5.2 with prometheus support you need to compile from scratch for Ubuntu.
# Debian repo has 4.5.2 now for bookworm and Ubuntu >22.04
version="4.5.2"
detect_linux_distribution() {
  # Function to see if a specific linux distribution is supported by this script
  # If it is supported then the global variable SETUP_ENTRYPOINT is set to the
  # function to be executed for the FS setup
  local distro_name=$(lsb_release -si)
  local distro_version=$(lsb_release -sr)
  local distro_codename=$(lsb_release -sc)
  DISTRO="$distro_name"
  DISTRO_VERSION="$distro_version"
  DISTRO_CODENAME="$distro_codename"
  case "$distro_name" in
    Ubuntu ) case "$distro_version" in
               20.04* | 22.04* ) SETUP_ENTRYPOINT="ubuntu_choice"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    Debian ) case "$distro_version" in
            10* | 11* | 12* ) SETUP_ENTRYPOINT="setup_apt"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    *      ) return 1 ;; # Unsupported Distribution
 esac
}

ubuntu_choice() {
# Also get entrypoint for the install
  echo "Press 1 to use apt (No Prometheus support for 20.04 - ok for other Debian based distros)"
  echo "Press 2 to install manually (with Prometheus support for 20.04)"
  options=("1" "2")
  select choice in "${options[@]}"
  do 
    case $choice in
      "1")
        SETUP_ENTRYPOINT="setup_apt"
        break
        ;;
      "2")
        SETUP_ENTRYPOINT="setup_manual"
        break
        ;;
      *)
        echo "Invalid option"
        ;;
  esac
  done
}

setup_apt() {
  sudo apt-get install -y coturn 
}

setup_manual() {
  apt update
  cd /usr/
  apt install -y make git build-essential pkg-config libssl-dev libevent-dev libmicrohttpd-dev libsystemd-dev libhiredis0.14 libmysqlclient21 libpq5 mysql-common sqlite3
  wget https://github.com/digitalocean/prometheus-client-c/releases/download/v0.1.3/libprom-dev-0.1.3-Linux.deb
  wget https://github.com/digitalocean/prometheus-client-c/releases/download/v0.1.3/libpromhttp-dev-0.1.3-Linux.deb
  sudo dpkg -i libprom-dev-0.1.3-Linux.deb
  sudo dpkg -i libpromhttp-dev-0.1.3-Linux.deb
  git clone --branch $version --single-branch https://github.com/coturn/coturn.git
  cd /usr/coturn
  nano configure
# Change CONFDIR location to /etc
# Change the PREFIX location as /usr - was /usr/local
# Or simlink after testing this
  ./configure
  make && make install
  mkdir /var/log/coturn
}

reboot_selection() {
  echo "Install done. Press 1 to reboot..."
  echo "Otherwise press any other key to exit"
  options=("1")
  select choice in "${options[@]}"
  do 
    case $choice in
      "1")
        echo "Rebooting now..."
        sudo reboot
        break
        ;;
      *)
        echo "You pressed a key! Exiting..."
        break
        ;;
  esac
  done
}

banner_start() {
  clear;
  echo "Installing CoTURN on $distro_name"
  echo "Standby"
  echo;
}

banner_end() {
  clear;
  echo "Hopefully CoTURN is now installed on $distro_name"
  echo "Run turnserver to be sure after rebooting"
  echo;
}

# Actual install logic
start_app() {
  detect_linux_distribution
    
  banner_start

  $SETUP_ENTRYPOINT

  banner_end

  reboot_selection
    
}


######################################################################
#
# Start of main script
#
######################################################################

[[ "$0" == "$BASH_SOURCE" ]] && start_app
