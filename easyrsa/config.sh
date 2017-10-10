#!/bin/bash

cd /etc/easyrsa/
echo 'easyrsa_ca' | ./easyrsa build-ca nopass
./easyrsa gen-dh
