lxc launch ubuntu:16.04 cnt-ubuntu-base
sleep 15

lxc exec cnt-ubuntu-base -- \
    bash -c "echo 'cnt-ubuntu-base>' \
        && apt update \
        && apt upgrade -y \
        && apt autoremove -y \
        && echo '<cnt-ubuntu-base'"

lxc restart cnt-ubuntu-base

lxc stop cnt-ubuntu-base
lxc copy cnt-ubuntu-base cnt-easyrsa-base

lxc start cnt-easyrsa-base
sleep 10

lxc exec cnt-easyrsa-base -- \
    bash -c "echo 'cnt-easyrsa-base>' \
        && wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.3/EasyRSA-3.0.3.tgz \
        && tar zxvfP EasyRSA-3.0.3.tgz --transform 's!^EasyRSA-3.0.3!/etc/easyrsa!' \
        && chown -R 0:0 /etc/easyrsa/ \
        && cd /etc/easyrsa/ \
        && ./easyrsa init-pki \
        && echo '<cnt-easyrsa-base'"

lxc restart cnt-easyrsa-base

lxc stop cnt-easyrsa-base
lxc copy cnt-easyrsa-base cnt-easyrsa
lxc copy cnt-easyrsa-base cnt-openvpn-base

lxc start cnt-easyrsa
lxc start cnt-openvpn-base
sleep 10

lxc exec cnt-openvpn-base -- \
    bash -c "echo 'cnt-openvpn-base>' \
        && wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - \
        && echo 'deb http://build.openvpn.net/debian/openvpn/release/2.4 xenial main' > /etc/apt/sources.list.d/openvpn.list \
        && apt update \
        && apt install -y openvpn \
        && ln -s /etc/easyrsa/ /etc/openvpn/ \
        && echo '<cnt-openvpn-base'"

lxc restart cnt-openvpn-base

lxc stop cnt-openvpn-base
lxc copy cnt-openvpn-base cnt-server
lxc copy cnt-openvpn-base cnt-client

lxc start cnt-server
lxc start cnt-client
sleep 10

lxc file push ./server/server.conf cnt-server/etc/openvpn/
lxc file push ./client/client.conf cnt-client/etc/openvpn/

lxc exec cnt-easyrsa -- \
    bash -c "echo 'cnt-easyrsa>' \
        && cd /etc/easyrsa/ \
        && echo 'easyrsa_ca' | ./easyrsa build-ca nopass \
        && ./easyrsa gen-dh \
        && echo '<cnt-easyrsa'"

lxc restart cnt-easyrsa

SERVER_NAME=openvpn_svr
CLIENT_NAME=openvpn_clt1

lxc exec cnt-server --env SERVER_NAME=$SERVER_NAME -- \
    bash -c "echo 'cnt-server>' \
        && cd /etc/easyrsa/ \
        && echo '' | ./easyrsa gen-req $SERVER_NAME nopass \
        && echo '<cnt-server'"

lxc exec cnt-client --env CLIENT_NAME=$CLIENT_NAME -- \
    bash -c "echo 'cnt-client>' \
        && cd /etc/easyrsa/ \
        && echo '' | ./easyrsa gen-req $CLIENT_NAME nopass \
        && echo '<cnt-client'"

lxc file pull cnt-server/etc/easyrsa/pki/reqs/$SERVER_NAME.req ./temp/
