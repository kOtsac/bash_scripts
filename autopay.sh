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
