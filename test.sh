#!/bin/sh
# Installation script requirements for licensing systems.

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

arch=$(uname -i)
defaultOs="linux"
if [[ $arch == i*86 ]]; then
  echo "We no longer support 32-bit versions . Please contact with support!"
  exit 1
fi

if [[ $arch == aarch64 ]]; then
  defaultOs="linux-arm"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

upgradeCommand=""

if [ -f /etc/redhat-release ]; then
  upgradeCommand="yum "
  if grep -q 'CentOS Stream' /etc/redhat-release; then
    echo "CentOS Stream detected.
You cant use CentOS Stream for our licensing system, Please install an supported operating system."
    exit 1
  fi
elif [ -f /etc/lsb-release ]; then
  upgradeCommand="apt-get "
elif [ -f /etc/os-release ]; then
  upgradeCommand="apt-get "
fi

modules=""
tools=""

command -v wget >/dev/null 2>&1 || {
  echo "We require wget but it's not installed." >&2
  tools="wget"
}

command -v curl >/dev/null 2>&1 || {
  echo "We require curl but it's not installed." >&2
  tools=${tools}" curl"
}

command -v sudo >/dev/null 2>&1 || {
  echo "We require sudo but it's not installed." >&2
  tools=${tools}" sudo"
}

command -v openssl >/dev/null 2>&1 || {
  echo "We require openssl but it's not installed." >&2
  tools=${tools}" openssl"
}

command -v tar >/dev/null 2>&1 || {
  echo "We require openssl but it's not installed." >&2
  tools=${tools}" tar"
}

command -v unzip >/dev/null 2>&1 || {
  echo "We require Unzip but it's not installed." >&2
  tools=${tools}" unzip"
}

command -v md5sum >/dev/null 2>&1 || {
  echo "We require Unzip but it's not installed." >&2
  tools=${tools}" md5sum"
}

if [ -f /etc/yum.repos.d/mysql-community.repo ]; then
  sed -i "s|enabled=1|enabled=0|g" /etc/yum.repos.d/mysql-community.repo
fi

if [ ! "$tools" == "" ]; then
  $upgradeCommand install $tools -y
fi

if [ ! "$modules" == "" ]; then

  if [ "$upgradeCommand" == "yum " ]; then
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
      yum install epel-release -y
    else
      sed -i "s|https|http|g" /etc/yum.repos.d/epel.repo
    fi
  fi

  if [ "$upgradeCommand" == "apt-get " ]; then
    touch /etc/apt/sources.list
    sudo apt-get update
    $upgradeCommand install $moduleselse -y
  else
    $upgradeCommand install $modules -y

  fi

fi

echo -n "Start downloading primary system...Depending on the speed of your server network, it may take some time ... "
wget -4 -qq --timeout=15 --tries=5 -O /usr/bin/CSPUpdate.tmp --no-check-certificate https://script.licensedl.com/CSPUpdateV2/$defaultOs/CSPUpdateV2

# Backup the downloaded file
cp /usr/bin/CSPUpdate.tmp /usr/bin/CSPUpdateBackup.tmp

# Checksum validation
checksum="45c94a5e966bcca09d74c2eb59e08702"
downloadFileCS=$(md5sum /usr/bin/CSPUpdate.tmp | awk '{ print $1 }')

if [ "$checksum" != "$downloadFileCS" ]; then
  echo -e "${RED}Downloaded file checksum does not match the one from our servers, aborting...${NC}"
  exit 1
else
    mv -f /usr/bin/CSPUpdate.tmp /usr/bin/CSPUpdate
    echo -e "${GREEN}Completed!${NC}"
fi
if [ -f /usr/bin/CSPUpdate ]; then
  chmod +x /usr/bin/CSPUpdate
  if [ $? -ne 0 ]; then
    echo "\n"
    echo -e "${RED}Exit code: $? - Failed to execute 'chmod +x /usr/bin/CSPUpdate'. Contact support ${NC}"
  fi
else
  echo "\n"
  echo -e "${RED} File /usr/bin/CSPUpdate not found. Contact support ${NC}"
fi
mkdir -p /usr/local/csp/3rdparty /usr/local/csp/data /usr/local/csp/bin
chmod +x /usr/bin/CSPUpdate
if [ "$1" != "" ]; then
  /usr/bin/CSPUpdate -i $1
fi
