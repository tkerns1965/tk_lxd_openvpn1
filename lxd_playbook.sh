lxc launch ubuntu:16.04 ubuntu-base
sleep 15

lxc exec ubuntu-base -- \
    bash -c "echo 'ubuntu-base>' \
        && apt update \
        && apt upgrade -y \
        && apt autoremove -y \
        && echo '<ubuntu-base'"

lxc restart ubuntu-base
lxc stop ubuntu-base
lxc copy ubuntu-base easyrsa-base
lxc start easyrsa-base
sleep 10

lxc exec easyrsa-base -- \
    bash -c "echo 'easyrsa-base>' \
        && wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.3/EasyRSA-3.0.3.tgz \
        && tar zxvfP EasyRSA-3.0.3.tgz --transform 's!^EasyRSA-3.0.3!/etc/easyrsa!' \
        && chown -R 0:0 /etc/easyrsa/ \
        && cd /etc/easyrsa/ \
        && ./easyrsa init-pki \
        && echo '<easyrsa-base'"

lxc restart easyrsa-base
lxc stop easyrsa-base
lxc copy easyrsa-base openvpn-base
lxc start openvpn-base
sleep 10

lxc exec ovpn-base -- \
    bash -c "echo 'ovpn-base>' \
        && wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - \
        && echo 'deb http://build.openvpn.net/debian/openvpn/release/2.4 xenial main' > /etc/apt/sources.list.d/openvpn.list \
        && apt update \
        && apt install -y openvpn \
        && ln -s /etc/easyrsa/ /etc/openvpn/ \
        && echo '<ovpn-base'"

lxc restart ovpn-base
lxc stop ovpn-base
lxc copy ovpn-base ovpn-svr
lxc start ovpn-svr
sleep 10

lxc copy ovpn-base ovpn-clt
lxc start ovpn-clt
sleep 10

lxc file push ./server/server.conf ovpn-svr/etc/openvpn/
lxc file push ./client/client.conf ovpn-clt/etc/openvpn/

lxc exec ovpn-svr -- \
    bash -c "echo 'ovpn-svr>' \
        && sed -i 's/#AUTOSTART=\"all\"/AUTOSTART=\"all\"/' /etc/default/openvpn \
        && sed -i 's/LimitNPROC=10/#LimitNPROC=10/' /lib/systemd/system/openvpn@.service \
        && systemctl daemon-reload \
        && echo '<ovpn-svr'"

lxc exec ovpn-clt -- \
    bash -c "echo 'ovpn-clt>' \
        && sed -i 's/#AUTOSTART=\"all\"/AUTOSTART=\"all\"/' /etc/default/openvpn \
        && sed -i 's/LimitNPROC=10/#LimitNPROC=10/' /lib/systemd/system/openvpn@.service \
        && systemctl daemon-reload \
        && echo '<ovpn-clt'"

lxc copy easyrsa-base easyrsa
lxc start easyrsa
sleep 10

lxc exec easyrsa -- \
    bash -c "echo 'easyrsa>' \
        && cd /etc/easyrsa/ \
        && echo 'easyrsa_ca' | ./easyrsa build-ca nopass \
        && ./easyrsa gen-dh \
        && echo '<easyrsa'"

lxc restart easyrsa

SERVER_NAME=ovpn_svr
CLIENT_NAME=ovpn_clt1

lxc exec ovpn-svr --env SERVER_NAME=$SERVER_NAME -- \
    bash -c "echo 'ovpn-svr>' \
        && cd /etc/easyrsa/ \
        && echo '' | ./easyrsa gen-req $SERVER_NAME nopass \
        && echo '<ovpn-svr'"

lxc exec ovpn-clt --env CLIENT_NAME=$CLIENT_NAME -- \
    bash -c "echo 'ovpn-clt>' \
        && cd /etc/easyrsa/ \
        && echo '' | ./easyrsa gen-req $CLIENT_NAME nopass \
        && echo '<ovpn-clt'"

lxc file pull ovpn-svr/etc/easyrsa/pki/reqs/$SERVER_NAME.req ./temp/
lxc file pull ovpn-clt/etc/easyrsa/pki/reqs/$CLIENT_NAME.req ./temp/

lxc file push ./temp/$SERVER_NAME.req easyrsa/root/
lxc file push ./temp/$CLIENT_NAME.req easyrsa/root/

lxc exec easyrsa --env SERVER_NAME=$SERVER_NAME -- \
    bash -c "echo 'easyrsa>' \
        && cd /etc/easyrsa/ \
        && ./easyrsa import-req /root/$SERVER_NAME.req $SERVER_NAME \
        && rm /root/$SERVER_NAME.req \
        && echo 'yes' | bash ./easyrsa sign-req server $SERVER_NAME \
        && echo '<easyrsa'"

lxc exec easyrsa --env CLIENT_NAME=$CLIENT_NAME -- \
    bash -c "echo 'easyrsa>' \
        && cd /etc/easyrsa/ \
        && ./easyrsa import-req /root/$CLIENT_NAME.req $CLIENT_NAME \
        && rm /root/$CLIENT_NAME.req \
        && echo 'yes' | bash ./easyrsa sign-req client $CLIENT_NAME \
        && echo '<easyrsa'"

rm ./temp/*

lxc file pull easyrsa/etc/easyrsa/pki/ca.crt ./temp/
lxc file pull easyrsa/etc/easyrsa/pki/dh.pem ./temp/
lxc file pull easyrsa/etc/easyrsa/pki/issued/$SERVER_NAME.crt ./temp/
lxc file pull easyrsa/etc/easyrsa/pki/issued/$CLIENT_NAME.crt ./temp/

lxc file push ./temp/ca.crt ovpn-svr/etc/easyrsa/pki/
lxc file push ./temp/ca.crt ovpn-clt/etc/easyrsa/pki/
lxc file push ./temp/dh.pem ovpn-svr/etc/easyrsa/pki/
lxc file push ./temp/dh.pem ovpn-clt/etc/easyrsa/pki/
lxc file push ./temp/$SERVER_NAME.crt ovpn-svr/etc/easyrsa/pki/
lxc file push ./temp/$CLIENT_NAME.crt ovpn-clt/etc/easyrsa/pki/

rm ./temp/*

lxc restart ovpn-svr
lxc restart ovpn-clt
