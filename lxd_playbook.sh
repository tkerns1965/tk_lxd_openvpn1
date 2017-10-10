lxc launch ubuntu:16.04 cnt-ubuntu-base

lxc exec cnt-ubuntu-base -- apt update
lxc exec cnt-ubuntu-base -- apt upgrade -y
lxc exec cnt-ubuntu-base -- apt autoremove -y

lxc restart cnt-ubuntu-base
lxc stop cnt-ubuntu-base
lxc copy cnt-ubuntu-base cnt-easyrsa-base
lxc start cnt-easyrsa-base

lxc exec cnt-easyrsa-base -- wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.3/EasyRSA-3.0.3.tgz
lxc exec cnt-easyrsa-base -- tar zxvfP EasyRSA-3.0.3.tgz --transform 's!^EasyRSA-3.0.3!/etc/easyrsa!'
lxc exec cnt-easyrsa-base -- chown -R 0:0 /etc/easyrsa/
lxc exec cnt-easyrsa-base -- bash -c "cd /etc/easyrsa/ && ./easyrsa init-pki"

lxc restart cnt-easyrsa-base
lxc stop cnt-easyrsa-base
lxc copy cnt-easyrsa-base cnt-easyrsa
lxc start cnt-easyrsa

lxc exec cnt-easyrsa -- bash -c "cd /etc/easyrsa/ && echo 'easyrsa_ca' | ./easyrsa build-ca nopass"
lxc exec cnt-easyrsa -- bash -c "cd /etc/easyrsa/ && ./easyrsa gen-dh"
