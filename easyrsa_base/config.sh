#!/bin/bash

wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.3/EasyRSA-3.0.3.tgz
tar zxvfP EasyRSA-3.0.3.tgz --transform 's!^EasyRSA-3.0.3!/etc/easyrsa!'
chown -R 0:0 /etc/easyrsa/
cd /etc/easyrsa/
./easyrsa init-pki
