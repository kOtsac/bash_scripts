#!/bin/bash
PORT=9009
APIPATH=/home/kotsac/idena0/datadir/
COLD_PATH=/home/kotsac/
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
CURRENTDIR=$(pwd)

cd $APIPATH
API_KEY=$(cat api.key)
cold=$(cat cold)
cd $COLD_PATH
mycold=$(cat mycold)

cd $CURRENTDIR
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
DATA2='{"method": "dna_getBalance","params":["'$ADR'"],"id": 3,"key":"'$API_KEY'"}'
BAL=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA2" | jq -r '.result.balance')
echo adr = $ADR
echo ip=$IP
echo bal=$BAL
MOI=$(jq -n $BAL/10)
echo moi=$MOI
PROFIT=$(jq -n $BAL-$MOI-1)
echo $PROFIT
DATA3='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$mycold'","amount": "'$MOI'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA3"
DATA4='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$cold'","amount": "'$PROFIT'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA4"


####
#!/bin/bash
PORT=9010
APIPATH=/home/kotsac/idena1/datadir/
COLD_PATH=/home/kotsac/
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
CURRENTDIR=$(pwd)

cd $APIPATH
API_KEY=$(cat api.key)
cold=$(cat cold)
cd $COLD_PATH
mycold=$(cat mycold)

cd $CURRENTDIR
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
DATA2='{"method": "dna_getBalance","params":["'$ADR'"],"id": 3,"key":"'$API_KEY'"}'
BAL=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA2" | jq -r '.result.balance')
echo adr = $ADR
echo ip=$IP
echo bal=$BAL
MOI=$(jq -n $BAL/10)
echo moi=$MOI
PROFIT=$(jq -n $BAL-$MOI-1)
echo $PROFIT
DATA3='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$mycold'","amount": "'$MOI'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA3"
DATA4='{"method": "dna_sendTransaction","params": [{"from": "'$ADR'","to": "'$cold'","amount": "'$PROFIT'"}],"id": 1,"key": "'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA4"
