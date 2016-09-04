echo "Downloading tarball for centOS 6..."
(
  curl -sL -o pe-latest.tgz 'https://pm.puppetlabs.com/cgi-bin/download.cgi?ver=latest&dist=el&arch=x86_64&rel=6' > /dev/null 2>&1
  tar zxf pe-latest.tgz > /dev/null 2>&1
  rm pe-latest.tgz
)

echo "Ready to Install. (automate this in future with the provided answer file)"
