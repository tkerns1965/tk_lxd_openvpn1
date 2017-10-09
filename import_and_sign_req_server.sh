#!/bin/bash

COMMON_NAME=$1

if [ -z "$COMMON_NAME" ]; then
  echo "No common name specified."
  exit 1
fi

cd /etc/easyrsa/

./easyrsa import-req /svr_pki/reqs/$COMMON_NAME.req $COMMON_NAME
echo "yes" | bash ./easyrsa sign-req server $COMMON_NAME

cp /etc/easyrsa/pki/ca.crt /svr_pki/ca.crt
cp /etc/easyrsa/pki/dh.pem /svr_pki/dh.pem
cp /etc/easyrsa/pki/issued/$COMMON_NAME.crt /svr_pki/$COMMON_NAME.crt
