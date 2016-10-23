#!/bin/bash

VAGRANT_DIR=$1
PE_PATH=$2
DISTRIBUTION=$3
ARCH=$4
RELEASE=$5
VERSION=$6

# check if the file already exists
if [ ! -f "${VAGRANT_DIR}/${PE_PATH}" ]; then
  echo "Downloading the latest version of Puppet Enterprise (to the local machine)..."
  curl -sL -o "${VAGRANT_DIR}/${PE_PATH}" "https://pm.puppetlabs.com/cgi-bin/download.cgi?ver=${VERSION}&dist=${DISTRIBUTION}&arch=${ARCH}&rel=${RELEASE}"
fi
