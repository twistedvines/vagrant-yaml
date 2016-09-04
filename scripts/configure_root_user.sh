#!/bin/bash
echo "Changing root password..."
(
  echo 'puppet' | passwd root --stdin
)
