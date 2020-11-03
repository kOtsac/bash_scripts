#!/bin/bash
PORT=9009
ADRS=$(cat /home/kotsac/adress0)
IP=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
API_KEY=$(cat /home/kotsac/idena0/datadir/api.key)
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
if [ "$ADRS" != "$ADR" ];
then
        systemctl restart idena0.service
        echo "idena0" date  >> /home/kotsac/logwatch.txt
else
        echo idena0 looks fine
fi
PORT=9010
ADRS=$(cat /home/kotsac/adress1)
API_KEY=$(cat /home/kotsac/idena1/datadir/api.key)
DATA='{"method": "dna_getCoinbaseAddr","params":[],"id": 8,"key":"'$API_KEY'"}'
ADR=$(curl http://$IP:$PORT -H "content-type:application/json;" -d "$DATA" | jq -r '.result')
if [ "$ADRS" != "$ADR" ]; then
        systemctl restart idena1.service
        echo "idena1" `date`   >> /home/kotsac/logwatch.txt

else
        echo idena1 looks fine
fi

echo watched `date` >> /home/kotsac/sudolog.txt
