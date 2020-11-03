PORT=9009

IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
API_KEY=$(cat /home/kotsac/idena0/datadir/api.key)
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result' > /home/kotsac/adress0


PORT=9010

API_KEY=$(cat /home/kotsac/idena1/datadir/api.key)
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result' > /home/kotsac/adress1
