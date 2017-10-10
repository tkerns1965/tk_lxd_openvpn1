lxc launch ubuntu:16.04 cnt-ubuntu-base
sleep 15

lxc exec cnt-ubuntu-base -- \
    bash -c "apt update \
        && apt upgrade -y \
        && apt autoremove -y"

lxc restart cnt-ubuntu-base
lxc stop cnt-ubuntu-base
lxc copy cnt-ubuntu-base cnt-easyrsa-base
lxc start cnt-easyrsa-base
sleep 10

lxc exec cnt-easyrsa-base -- \
    bash -c "wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.3/EasyRSA-3.0.3.tgz \
        && tar zxvfP EasyRSA-3.0.3.tgz --transform 's!^EasyRSA-3.0.3!/etc/easyrsa!' \
        && chown -R 0:0 /etc/easyrsa/ \
        && cd /etc/easyrsa/ \
        && ./easyrsa init-pki"

lxc restart cnt-easyrsa-base
lxc stop cnt-easyrsa-base
lxc copy cnt-easyrsa-base cnt-easyrsa
lxc start cnt-easyrsa
sleep 10

lxc exec cnt-easyrsa -- \
    bash -c "cd /etc/easyrsa/ \
        && echo 'easyrsa_ca' | ./easyrsa build-ca nopass \
        && ./easyrsa gen-dh"

lxc restart cnt-easyrsa
lxc copy cnt-easyrsa-base cnt-openvpn-base
lxc start cnt-openvpn-base
sleep 10

lxc file push ./openvpn_base/gen_req.sh cnt-openvpn-base/root/

lxc exec cnt-openvpn-base -- \
    bash -c "wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - \
        && echo 'deb http://build.openvpn.net/debian/openvpn/release/2.4 xenial main' > /etc/apt/sources.list.d/openvpn.list \
        && apt update \
        && apt install -y openvpn \
        && # apt install -y openssh-client \
        && # apt install -y iputils-ping \
        && ln -s /etc/easyrsa/ /etc/openvpn/ \
        && chmod u+x /root/gen_req.sh"
