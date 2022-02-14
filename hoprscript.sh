apt update -y
apt install tmux git jq unzip iptables -y
# Entering variables
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
read -p 'Username: ' uservar
read -sp 'Password: ' pass0
read -sp 'Repeat Password: ' pass1
echo
while [ $pass0 != $pass1 ]
do
echo Passwords does not match. Enter them again
read -sp 'Password: ' pass0
echo
read -sp 'Repeat Password: ' pass1
done
useradd -m -G sudo -p $(perl -e 'print crypt($ARGV[0], "password")' $pass0) -s /bin/bash $uservar
pass0=0

read -p 'ssh port: ' v_ssh_port
read -p 'Public Key: ' pubkey



sed -i "s/#Port 22/Port $v_ssh_port/" /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/UsePAM yes/UsePAM no/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/passwordauthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
#swap memory
read -p 'Size of swap memory. for example: 1G  : ' swap_memory
fallocate -l $swap_memory /swapfile2 && sudo chmod 600 /swapfile2 && sudo mkswap /swapfile2 && sudo swapon /swapfile2 && echo '/swapfile2 none swap sw 0 0' | sudo tee -a /etc/fstab


#Broutforce difence


iptables -A INPUT -p tcp -m tcp --dport $v_ssh_port -m state --state NEW -m hashlimit --hashlimit 1/hour --hashlimit-burst 2 --hashlimit-mode srcip --hashlimit-name SSH --hashlimit-htable-expire 60000 -j ACCEPT

iptables -A INPUT -p tcp -m tcp --dport $v_ssh_port --tcp-flags SYN,RST,ACK SYN -j DROP

iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport $v_ssh_port -j ACCEPT

mkdir /etc/iptables

iptables-save > /etc/iptables/iptables.rules

cat >> /etc/systemd/system/iptables-rules-restore.service <<EOF
[Unit]
Description = Apply iptables rules
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'iptables-restore < /etc/iptables/iptables.rules'
[Install]
WantedBy=network-pre.target
EOF

chmod +x /etc/systemd/system/iptables-rules-restore.service

systemctl enable iptables-rules-restore.service

systemctl daemon-reload

systemctl start iptables-rules-restore.service

###

mkdir /home/$uservar/.ssh

echo $pubkey >> /home/$uservar/.ssh/authorized_keys

systemctl reload sshd.service

apt-get update

apt-get install \
         ca-certificates \
    curl \
    gnupg \
    lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io


read -p 'Node security token(it must include min 8 : letter up & down, symbol (!!! not % !!!) , numeral ): ' node_token
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

docker pull hopr/hoprd:wildhorn-v2
docker pull gcr.io/hoprassociation/hoprd:latest-wildhorn-v2
mkdir -p /home/$uservar/hopr/
cat > /home/$uservar/docker.sh <<EOF
#!/bin/bash
docker run -d  --pull always -ti -v $uservar/.hoprd-db:/app/db -p 9091:9091 -p 3000:3000 -p 3001:3001 gcr.io/hoprassociation/hoprd:athens --admin --password 'open-sesame-iTwnsPNg0hpagP+o6T0KOwiH9RQ0' --init --rest --restHost "0.0.0.0" --restPort 3001 --identity /app/db/.hopr-id-athens --apiToken '$node_token' --adminHost "0.0.0.0" --adminPort 3000 --host "0.0.0.0:9091"
#docker run -d  --pull always -ti -v $uservar/.hoprd-db-bob:/app/db -p 9091:9091 -p 3000:3000 -p 3001:3001 gcr.io/hoprassociation/hoprd:athens --admin --password 'open-sesame-iTwnsPNg0hpagP+o6T0KOwiH9RQ0' --init --rest --restHost "0.0.0.0" --restPort 3001 --identity /app/db/.hopr-id-athens --apiToken '$node_token' --adminHost "0.0.0.0" --adminPort 3000 --host "0.0.0.0:9091"
#docker run -d  --pull always -ti -v $uservar/.hoprd-db-alice:/app/db -p 9091:9091 -p 3000:3000 -p 3001:3001 gcr.io/hoprassociation/hoprd:athens --admin --password 'open-sesame-iTwnsPNg0hpagP+o6T0KOwiH9RQ0' --init --rest --restHost "0.0.0.0" --restPort 3001 --identity /app/db/.hopr-id-athens --apiToken '$node_token' --adminHost "0.0.0.0" --adminPort 3000 --host "0.0.0.0:9091"
EOF
cat > /home/$uservar/stop_docker.sh <<EOF
#!/bin/bash
sudo docker stop $(sudo docker ps -q)
EOF
chmod +x /home/$uservar/stop_docker.sh
chmod +x /home/$uservar/docker.sh
echo "*/1 * * * * /home/$uservar/docker.sh" >> /var/spool/cron/crontabs/root
service cron reload
echo Done. System will rebooted now
reboot
