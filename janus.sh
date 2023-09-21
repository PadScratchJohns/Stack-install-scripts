#!/bin/bash

sudo apt-get install -y lsb-release
# apt versions are different per distro - check with apt-cache policy janus to check which one you get
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
               20.04* | 22.04* ) SETUP_ENTRYPOINT="setup_apt"
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


setup_apt() {
  sudo apt-get install -y janus 
  VERSION="janus --version"
}

setup_manual() {
# Confirmed working on 20.04 - haven't tested this script but manually this works. 
  apt-get install -y apt-utils libmicrohttpd-dev libjansson-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libusrsctp1 libusrsctp-dev libcurl4-openssl-dev liblua5.3-dev libconfig-dev pkg-config gengetopt libtool automake autoconf cmake gtk-doc-tools libini-config-dev libcollection-dev autotools-dev make git doxygen graphviz ffmpeg python3-pip sudo
# pip install of meson & Ninja
  pip3 install meson ninja
# lib websockets
  mkdir janus-build
  cd janus-build
  git clone https://libwebsockets.org/repo/libwebsockets
  cd libwebsockets
  mkdir build
  cd build
  cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" ..
  make && sudo make install
  cd ../..
# lib nice
  git clone https://gitlab.freedesktop.org/libnice/libnice
  cd libnice
  meson --prefix=/usr build && ninja -C build && sudo ninja -C build install
  cd ..
# libsrtp2
  wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz
  tar xfv v2.2.0.tar.gz
  cd libsrtp-2.2.0
  ./configure --prefix=/usr --enable-openssl
  make shared_library && sudo make install
  cd ..
# Janus:
  git clone https://github.com/meetecho/janus-gateway.git
  cd janus-gateway
  sh autogen.sh
  ./configure --prefix=/opt/janus
  make
  make install
  mkdir /var/log/janus
  cd /opt/janus/bin
  ./janus --version
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
  echo "Installing Janus $VERSION on $distro_name"
  echo "Standby"
  echo;
}

banner_end() {
  clear;
  echo "Hopefully Janus $VERSION is now installed on $distro_name"
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
