#!/bin/bash
systemctl stop idena0
version=$1
cd /home/kotsac/idena0 && wget https://github.com/idena-network/idena-go/releases/download/v$version/idena-node-linux-$version
systemctl stop idena1
chmod +x idena-node-linux-$version
cp /home/kotsac/idena0/idena-node-linux-$version /home/kotsac/idena1/
mv idena-node-linux-$version idena-go0
systemctl start idena0
mv /home/kotsac/idena1/idena-node-linux-$version /home/kotsac/idena1/idena-go1
systemctl start idena1
sleep 60
PORT=9009
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
API_KEY=$(cat /home/kotsac/idena0/datadir/api.key)
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
API_KEY=$(cat /home/kotsac/idena1/datadir/api.key)
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
