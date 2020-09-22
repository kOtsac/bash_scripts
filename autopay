#!/bin/bash
PORT=9009
APIPATH=/home/kotsac/idena0/datadir/
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
CURRENTDIR=$(pwd)
cd $APIPATH
API_KEY=$(cat api.key)
cd $CURRENTDIR
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
DATA2='{"method": "dna_getBalance","params":["'$ADR'"],"id": 3,"key":"'$API_KEY'"}'
BAL=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA2" | jq -r '.result.balance')
echo $ADR
#echo $IP
#BAL2=$(python3 -c "print(int($BAL))")
echo $BAL
#echo $BAL2
int=$((${BAL%.*}-1))
MOI_PROCENT=$(($int/10))
MOI=$(jq -n $int/10)
PROFIT=$(( $int-$MOI_PROCENT ))
echo $PROFIT
echo $MOI_PROCENT
echo $(( $PROFIT+$MOI_PROCENT ))
echo $MOI
DATA3='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "$mycold","amount": "'$MOI'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA3"
DATA4='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "$cold","amount": "'$PROFIT'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA4"
