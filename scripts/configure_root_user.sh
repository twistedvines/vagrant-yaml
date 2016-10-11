#!/bin/bash
echo "Changing root password..."
(
  echo 'root:puppet' | chpasswd
)
