#!/bin/bash
apt update
apt install screen

# Entering variables

read -p 'Username: ' uservar

read -sp 'Password: ' pass0
echo
read -sp 'Repeat Password: ' pass1
echo

while [ $pass0 != $pass1 ]
do

echo Passwords does not match. Enter them again

read -sp 'Password: ' pass0
echo
read -sp 'Repeat Password: ' pass1
echo
done

read -p 'ssh port: ' v_ssh_port

read -p 'Public Key: ' pubkey


useradd -m -G sudo -p $(perl -e 'print crypt($ARGV[0], "password")' $pass0) -s /bin/bash $uservar

pass0=0
sed -i "s/#Port 22/Port $v_ssh_port/" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/UsePAM yes/UsePAM no/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config


mkdir /home/$uservar/.ssh
echo $pubkey >> /home/$uservar/.ssh/authorized_keys

systemctl reload sshd.service

cat > /etc/systemd/system/idena0.service <<EOF
[Unit]
Description=Idena Node
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=kotsac
WorkingDirectory=/home/kotsac/idena0/
ExecStart=/home/kotsac/idena0/idena-go0 --config /home/kotsac/idena0/config.json
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target

EOF

cat > /etc/systemd/system/idena1.service <<EOF
[Unit]
Description=Idena Node
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$uservar
WorkingDirectory=/home/kotsac/idena1/
ExecStart=/home/kotsac/idena1/idena-go1 --config /home/kotsac/idena1/config.json
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

fallocate -l 1G /swapfile2 && sudo chmod 600 /swapfile2 && sudo mkswap /swapfile2 && sudo swapon /swapfile2 && echo '/swapfile2 none swap sw 0 0' | sudo tee -a /etc/fstab

cat > /etc/cron.daily/erize.sh <<EOF
#!/bin/bash
systemctl stop idena0.service idena1.service
rm -R /home/kotsac/idena0/datadir/ipfs
rm -R /home/kotsac/idena1/datadir/ipfs
sleep 10
reboot
EOF
chmod +x /etc/cron.daily/erize.sh
# nodes install
mkdir /home/$uservar/idena0 /home/$uservar/idena1
version=$1
cd /home/$uservar/idena0 && wget https://github.com/idena-network/idena-go/releases/download/v$version/idena-node-linux-$version
mv idena-node-linux-$version idena-go0
chmod +x idena-go0
cp /home/$uservar/idena0/idena-go0 /home/$uservar/idena1/idena-go1

cat /home/$uservar/idena0/config.json <<EOF
{
  "DataDir": "datadir",
  "P2P": {
    "MaxInboundPeers": 12,
    "MaxOutboundPeers": 6
  },
  "IpfsConf": {
    "Profile": "server",
    "IpfsPort": 40405,
    "BlockPinThreshold": 0.3,
    "FlipPinThreshold": 0.5
  },
  "RPC": {
    "HTTPHost": "localhost",
    "HTTPPort": 9009
  },
  "Sync": {
    "FastSync": true
  }
}

EOF
chmod +x /home/$uservar/idena0/config.json

cat /home/$uservar/idena1/config.json <<EOF
{
  "DataDir": "datadir",
  "P2P": {
    "MaxInboundPeers": 12,
    "MaxOutboundPeers": 6
  },
  "IpfsConf": {
    "Profile": "server",
    "IpfsPort": 40406,
    "BlockPinThreshold": 0.3,
    "FlipPinThreshold": 0.5
  },
  "RPC": {
    "HTTPHost": "localhost",
    "HTTPPort": 9010
  },
  "Sync": {
    "FastSync": true

  }
}


EOF
chmod +x /home/$uservar/idena1/config.json




/home/$uservar/idena0/idena-go0 &
sleep 10
echo
killall idena-go0
echo

cd /home/$uservar/idena1
./idena-go1 &
sleep 10
killall idena-go1
sleep 5
echo idena0 apikey
cat /home/$uservar/idena0/datadir/api.key
echo
echo idena0 key
cat /home/$uservar/idena0/datadir/keystore/nodekey
echo
echo idena1 apikey
cat /home/$uservar/idena1/datadir/api.key
echo
echo idena1 key
cat /home/$uservar/idena1/datadir/keystore/nodekey
echo

chown -R $uservar:$uservar /home/$uservar/idena0 /home/$uservar/idena1 
systemctl daemon-reload 
systemctl enable idena0.service	idena1.service
systemctl start idena0.service	idena1.service
echo done
