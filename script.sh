#!/bin/bash
apt update -y
apt install screen git jq -y

# Entering variables

IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
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
done
read -p 'ssh port: ' v_ssh_port
read -p 'Public Key: ' pubkey
read -p 'idena version: ' version
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
User=$uservar
WorkingDirectory=/home/$uservar/idena0/
ExecStart=/home/$uservar/idena0/idena-go0 --config /home/$uservar/idena0/config.json
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
WorkingDirectory=/home/$uservar/idena1/
ExecStart=/home/$uservar/idena1/idena-go1 --config /home/$uservar/idena1/config.json
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

fallocate -l 1G /swapfile2 && sudo chmod 600 /swapfile2 && sudo mkswap /swapfile2 && sudo swapon /swapfile2 && echo '/swapfile2 none swap sw 0 0' | sudo tee -a /etc/fstab

cat > /etc/cron.daily/erize <<EOF
#!/bin/bash
systemctl stop idena0.service idena1.service
rm -R /home/$uservar/idena0/datadir/ipfs /home/$uservar/idena1/datadir/ipfs
sleep 10
sudo reboot
EOF
chmod +x /etc/cron.daily/erize
# nodes install
mkdir /home/$uservar/idena0 /home/$uservar/idena1
cd /home/$uservar/idena0 && wget https://github.com/idena-network/idena-go/releases/download/v$version/idena-node-linux-$version
mv idena-node-linux-$version idena-go0
chmod +x idena-go0
cp /home/$uservar/idena0/idena-go0 /home/$uservar/idena1/idena-go1

cat > /home/$uservar/idena0/config.json <<EOF
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
    "HTTPHost": "$IP",
    "HTTPPort": 9009
  },
  "Sync": {
    "FastSync": true
  }
}

EOF
chmod +x /home/$uservar/idena0/config.json

cat > /home/$uservar/idena1/config.json <<EOF
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
    "HTTPHost": "$IP",
    "HTTPPort": 9010
  },
  "Sync": {
    "FastSync": true

  }
}


EOF
chmod +x /home/$uservar/idena1/config.json

cat >> /home/$uservar/update.sh <<EOF
#!/bin/bash
systemctl stop idena0
userdir=$uservar
version=\$1
cd /home/$uservar/idena0 && wget https://github.com/idena-network/idena-go/releases/download/v\$version/idena-node-linux-\$version
systemctl stop idena1
chmod +x idena-node-linux-\$version
cp /home/$uservar/idena0/idena-node-linux-\$version /home/$uservar/idena1/
mv idena-node-linux-\$version idena-go0
systemctl start idena0
mv /home/$uservar/idena1/idena-node-linux-\$version /home/$uservar/idena1/idena-go1
systemctl start idena1
scleep 30
EOF
cat >> /home/$uservar/update.sh <<'EOF'
PORT=9009
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
API_KEY=$(cat /home/$userdir/idena0/datadir/api.key)

DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADDR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
DATA='{"method": "dna_identity","params":["'$ADDR'"],"id": 9,"key":"'$API_KEY'"}'
STATUS=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result.online')

if [ $STATUS = "false" ]; then
   DATA='{"method":"dna_epoch","params":[],"id":4,"key":"'$API_KEY'"}'
   EPOCH=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result.epoch')
   DATA='{"method": "dna_becomeOnline","params": [{"nonce": 0,"epoch":'$EPOCH'}],"id": 1,"key":"'$API_KEY'"}'
   curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA"
fi

PORT=9010
API_KEY=$(cat /home/$userdir/idena1/datadir/api.key)
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADDR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
DATA='{"method": "dna_identity","params":["'$ADDR'"],"id": 9,"key":"'$API_KEY'"}'
STATUS=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result.online')

if [ $STATUS = "false" ]; then
   DATA='{"method":"dna_epoch","params":[],"id":4,"key":"'$API_KEY'"}'
   EPOCH=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result.epoch')
   DATA='{"method": "dna_becomeOnline","params": [{"nonce": 0,"epoch":'$EPOCH'}],"id": 1,"key":"'$API_KEY'"}'
   curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA"
fi


EOF
chmod +x /home/$uservar/update.sh

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

read -p 'Enter adm cold wallet :' mycold
echo $mycold >> /home/$uservar/mycold
read -p 'Enter idena0 cold wallet :' cold0
echo $cold0 >> /home/$uservar/idena0/cold0
read -p 'Enter idena1 cold wallet :' cold1
echo $cold1 >> /home/$uservar/idena1/cold1

cat > /home/$uservar/autopay.sh <<'EOF'
#!/bin/bash
PORT=9009
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
API_KEY=$(cat /home/$USER/idena0/datadir/api.key)
cold0=$(cat /home/$USER/idena0/cold0)
mycold=$(cat /home/$USER/mycold)

DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
DATA2='{"method": "dna_getBalance","params":["'$ADR'"],"id": 3,"key":"'$API_KEY'"}'
BAL=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA2" | jq -r '.result.balance')
MOI=$(jq -n $BAL/10)
PROFIT=$(jq -n $BAL-$MOI-1)
DATA3='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$mycold'","amount": "'$MOI'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA3"
DATA4='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$cold0'","amount": "'$PROFIT'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA4"
echo
echo server:$IP
echo
echo sours adr: $ADR : $BAL
echo to : $cold0 : $PROFIT
echo to : $mycold : $MOI 
echo

####

PORT=9010
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
API_KEY=$(cat /home/$USER/idena1/datadir/api.key)
cold1=$(cat /home/$USER/idena1/cold1)

DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
DATA2='{"method": "dna_getBalance","params":["'$ADR'"],"id": 3,"key":"'$API_KEY'"}'
BAL=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA2" | jq -r '.result.balance')
MOI=$(jq -n $BAL/10)
PROFIT=$(jq -n $BAL-$MOI-1)
DATA3='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$mycold'","amount": "'$MOI'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA3"
DATA4='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$cold1'","amount": "'$PROFIT'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA4"

echo
echo server:$IP
echo
echo sours adr: $ADR : $BAL
echo to : $cold1 : $PROFIT
echo to : $mycold : $MOI 
echo
EOF
chmod +x /home/$uservar/autopay.sh

#cron
echo "0 6 */3 * * /home/$uservar/autopay.sh" >> /var/spool/cron/crontabs/root

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
# vim set
cat > /home/$uservar/.vimrc <<EOF
set number
set expandtab
set tabstop=2
syntax on
set hlsearch
set incsearch

call plug#begin('~/.vim/plugged')

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" color
Plug 'morhetz/gruvbox'

call plug#end()
" mappingsi

map <C-n> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
set background=dark
let g:gruvbox_contrast_dark=('hard')

colorscheme gruvbox

EOF
curl -fLo /home/$uservar/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
chown -R $uservar:$uservar /home/$uservar
systemctl daemon-reload 
systemctl enable idena0.service	idena1.service
systemctl start idena0.service	idena1.service
echo done
