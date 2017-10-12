#!/bin/bash

wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
echo 'deb http://build.openvpn.net/debian/openvpn/release/2.4 xenial main' > /etc/apt/sources.list.d/openvpn.list
apt update
apt install -y openvpn
ln -s /etc/easyrsa/ /etc/openvpn/
