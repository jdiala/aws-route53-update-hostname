#!/bin/bash

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

HOSTED_ZONE_ID=`aws route53 list-hosted-zones | jq -r '.[][] | select(.Name="$HOSTNAME") .Id' | head -n 1`

aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID | jq -r '.[][] | select(.Type=="A") .ResourceRecords[].Value' | head -n 1 > /tmp/hostname-route53-value

IP=$(curl --silent https://api.ipify.org)
echo $IP
if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	exit 1
fi

if grep -Fxq "$IP" /tmp/hostname-route53-value; then
	echo "IP Has Not Changed, Exiting"
	exit 0
fi

echo "IP changed. Updating A record"

cat > /tmp/hostname-change-resource-record-sets.json << EOF
{
    "Comment": "Update record to reflect new IP address of home router",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$HOSTNAME.",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "$IP"
                    }
                ]
            }
        }
    ]
}
EOF

cat /tmp/hostname-change-resource-record-sets.json

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///tmp/hostname-change-resource-record-sets.json
