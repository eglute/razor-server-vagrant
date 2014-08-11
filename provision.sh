#!/usr/bin/env bash

sudo su -
apt-get update -y
apt-get install curl -y
apt-get install git -y
apt-get install build-essential -y

IP_ADDRESS=$1
IP_RANGE=$2
IP_BROADCAST=$3
cat > /etc/hosts <<EOF
127.0.0.1 localhost
$IP_ADDRESS razor.one
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

cat > /etc/hostname <<EOF
razor.one
EOF
hostname razor.one

sudo mkdir -p /var/lib/razor/repo-store
sudo mkdir -p /var/lib/tftpboot

apt-get install -y dnsmasq
apt-get install ntp -y

sudo /etc/init.d/networking restart
 
cat > /etc/dnsmasq.conf <<EOF
server=$IP_ADDRESS@eth1
interface=eth1
no-dhcp-interface=eth0
domain=razor.one
# conf-dir=/etc/dnsmasq.d
# This works for dnsmasq 2.45
# iPXE sets option 175, mark it for network IPXEBOOT
dhcp-match=IPXEBOOT,175
dhcp-boot=net:IPXEBOOT,bootstrap.ipxe
dhcp-boot=undionly.kpxe
# TFTP setup
enable-tftp
tftp-root=/var/lib/tftpboot
dhcp-range=$IP_ADDRESS,$IP_RANGE,12h

dhcp-option=option:ntp-server,$IP_ADDRESS

EOF

  
cat >> /etc/ntp.conf <<EOF
broadcast $IP_BROADCAST
EOF
service dnsmasq restart
echo service dnsmasq status
service dnsmasq status
sleep 10
echo service dnsmasq status
service dnsmasq status

iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface eth1 -j ACCEPT
iptables-save | sudo tee /etc/iptables.conf
iptables-restore < /etc/iptables.conf
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

sed -i "s/exit 0/iptables-restore < \/etc\/\iptables.conf \nexit 0/g" /etc/rc.local
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf

apt-get install postgresql libarchive-dev openjdk-7-jre-headless -y

sudo -i -u postgres psql -c "CREATE ROLE razor LOGIN PASSWORD 'razor';"
sudo -i -u postgres createdb -O razor razor_dev;
sudo -i -u postgres createdb -O razor razor_test
sudo -i -u postgres createdb -O razor razor_prd

service postgresql restart
mkdir -p /var/lib/razor/repo-store

cd   

git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc

source /root/.bashrc
cd /opt
#git clone https://github.com/puppetlabs/razor-server.git 
wget https://github.com/puppetlabs/razor-server/archive/0.15.0.tar.gz
tar -zxvf 0.15.0.tar.gz
cd razor-server-0.15.0/

git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash
rbenv install jruby-1.7.8
rbenv rehash && rbenv global jruby-1.7.8 
 
gem install bundler
 
bundle install
cp config.yaml.sample config.yaml

sed -i "s/jdbc:postgresql:razor_prd?user=razor&password=mypass/jdbc:postgresql:razor_prd\?user=razor\&password=razor/g" config.yaml
sed -i "s/jdbc:postgresql:razor_dev/jdbc:postgresql:razor_dev\?user=razor\&password=razor/g" config.yaml
sed -i "s/jdbc:postgresql:razor?user=razor&password=mypass/jdbc:postgresql:razor\?user=razor\&password=razor/g" config.yaml


rake db:migrate
torquebox deploy
torquebox run --bind-address 0.0.0.0 &

mkdir -p /var/lib/razor/repo-store
mkdir -p /var/lib/tftpboot
cd /tmp 
curl -L -O http://boot.ipxe.org/undionly.kpxe
mv undionly.kpxe /var/lib/tftpboot/

# hmmm the torquebox may not have fully started yet...
sleep 30
curl -L -O http://$IP_ADDRESS:8080/api/microkernel/bootstrap?nic_max=3

mv bootstrap* /var/lib/tftpboot/bootstrap.ipxe

curl -L -O http://links.puppetlabs.com/razor-microkernel-latest.tar
tar xf razor-microkernel-latest.tar -C /var/lib/razor/repo-store/

cd /opt

rbenv install 2.1.1
rbenv global 2.1.1
gem install razor-client

razor --url http://$IP_ADDRESS:8080/api nodes

cd
wget http://releases.ubuntu.com/precise/ubuntu-12.04.4-server-amd64.iso
razor create-repo --name=ubuntu_server --iso-url file:///root/ubuntu-12.04.4-server-amd64.iso --task ubuntu
razor create-broker --name=noop --broker-type=noop
razor create-tag --name small --rule '["=", ["num", ["fact", "processorcount"]], 1]'
cat > policy.json<<EOF
{
  "name": "ubuntu_one",
  "repo": { "name": "ubuntu_server" },
  "task": { "name": "ubuntu" },
  "broker": { "name": "noop" },
  "enabled": true,
  "hostname": "host${id}",
  "root_password": "secret",
  "max_count": "20",
  "tags": ["small"]
}
EOF

razor create-policy --json policy.json 

