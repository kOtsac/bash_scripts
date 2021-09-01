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
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

docker pull hopr/hoprd:matic
mkdir -p /home/$uservar/hopr/
cat > /home/$uservar/docker.sh <<EOF
#!/bin/bash
docker run -v $HOME/.hoprd-db-matic-1:/app/db -d -e DEBUG=hopr*  -p 9091:9091 -p 3000:3000  hopr/hoprd:matic  --password='h0pR-w1Lh0RN'  --init --announce  --identity /app/db/.hopr-identity  --testNoAuthentication  --admin --adminHost 0.0.0.0 --healthCheck --healthCheckHost 0.0.0.0
docker run -v $HOME/.hoprd-db-matic-2:/app/db -d -e DEBUG=hopr*  -p 9092:9092 -p 3010:3010  hopr/hoprd:matic  --password='h0pR-w1Lh0RN'  --init --announce  --identity /app/db/.hopr-identity  --testNoAuthentication  --admin --adminHost 0.0.0.0 --host "0.0.0.0:9092" --adminPort 3010 --healthCheck --healthCheckHost 0.0.0.0
EOF
reboot
