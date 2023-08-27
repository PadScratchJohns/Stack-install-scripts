#!/bin/bash

# For the Debian APT install you need a signalwire account and token. You can get one from here:
# https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Installation/HOWTO-Create-a-SignalWire-Personal-Access-Token_67240087/

sudo apt-get install -y lsb-release

detect_linux_distribution() {
  # Function to see if a specific linux distribution is supported by this script
  # If it is supported then the global variable SETUP_ENTRYPOINT is set to the
  # function to be executed for the system setup

  local cmd_lsb_release=$(locate_cmd "lsb_release")
  local distro_name=$($cmd_lsb_release -si)
  local distro_version=$($cmd_lsb_release -sr)
  DISTRO="$distro_name"
  DISTRO_VERSION="$distro_version"

  case "$distro_name" in
    Ubuntu ) case "$distro_version" in
               20.04* | 22.04* ) SETUP_ENTRYPOINT="setup_ubuntu"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    Debian ) case "$distro_version" in
            10* | 11* | 12* ) SETUP_ENTRYPOINT="setup_debian"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    *      ) return 1 ;; # Unsupported Distribution
 esac
}


# Latest debian release:
setup_debian() {
    # See 2nd line in script for this
    TOKEN=YOURSIGNALWIRETOKEN

    $cmd_apt_get update && $cmd_apt_get install -y gnupg2 wget

    wget --http-user=signalwire --http-password=$TOKEN -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg

    echo "machine freeswitch.signalwire.com login signalwire password $TOKEN" > /etc/apt/auth.conf
    chmod 600 /etc/apt/auth.conf
    echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
    echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

    # you may want to populate /etc/freeswitch at this point.
    # if /etc/freeswitch does not exist, the standard vanilla configuration is deployed
    $cmd_apt_get update && $cmd_apt_get install -y freeswitch-meta-all

}

# latest Ubuntu release: or you specific choice 
# Ubuntu 20.04 build from source: 
# Dependancies 
sudo apt update && apt upgrade -y
sudo apt install --yes build-essential pkg-config uuid-dev zlib1g-dev libjpeg-dev libsqlite3-dev libcurl4-openssl-dev \
            libpcre3-dev libspeexdsp-dev libldns-dev libedit-dev libtiff5-dev yasm libopus-dev libsndfile1-dev unzip \
            libavformat-dev libswscale-dev libavresample-dev liblua5.2-dev liblua5.2-0 cmake libpq-dev \
            unixodbc-dev autoconf automake ntpdate libxml2-dev libpq-dev libpq5 sngrep libvorbis0a libogg0 libogg-dev libvorbis-dev libshout3-dev libmpg123-dev libmp3lame-dev







