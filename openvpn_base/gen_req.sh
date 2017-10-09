#!/bin/bash

COMMON_NAME=$1

if [ -z "$COMMON_NAME" ]; then
  echo "No common name specified."
  exit 1
fi

cd /etc/easyrsa/

echo "" | ./easyrsa gen-req $COMMON_NAME nopass
