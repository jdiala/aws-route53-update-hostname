#!/bin/bash
#
# update-hosted-zone-by-hostname.sh
# Updates AWS Route53 A record with the current public IP address
#

set -euo pipefail

# Validate required environment variables
: "${AWS_ACCESS_KEY_ID:?Environment variable AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?Environment variable AWS_SECRET_ACCESS_KEY is required}"
: "${AWS_DEFAULT_REGION:?Environment variable AWS_DEFAULT_REGION is required}"
: "${HOSTNAME:?Environment variable HOSTNAME is required}"

# Optional TTL configuration (default: 300 seconds)
TTL="${TTL:-300}"

echo "Starting Route53 DNS update for hostname: ${HOSTNAME}"

# Get the hosted zone ID for the domain
# Note: HOSTNAME should be the full domain name (e.g., example.com)
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones | jq -r --arg hostname "${HOSTNAME}." '.HostedZones[] | select(.Name == $hostname) | .Id' | head -n 1)

if [[ -z "${HOSTED_ZONE_ID}" ]]; then
    echo "Error: Could not find hosted zone for hostname: ${HOSTNAME}"
    exit 1
fi

echo "Found hosted zone ID: ${HOSTED_ZONE_ID}"

# Get current A record value from Route53
CURRENT_ROUTE53_IP=$(aws route53 list-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" | jq -r --arg hostname "${HOSTNAME}." '.ResourceRecordSets[] | select(.Type=="A" and .Name == $hostname) | .ResourceRecords[].Value' | head -n 1)

echo "Current Route53 A record IP: ${CURRENT_ROUTE53_IP:-none}"

# Get current public IP
IP=$(curl --silent --fail --max-time 10 https://api.ipify.org) || {
    echo "Error: Failed to retrieve public IP address"
    exit 1
}

echo "Current public IP: ${IP}"

# Validate IP format
if [[ ! ${IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Error: Invalid IP address format: ${IP}"
    exit 1
fi

# Check if IP has changed
if [[ "${IP}" == "${CURRENT_ROUTE53_IP}" ]]; then
    echo "IP has not changed. No update needed."
    exit 0
fi

echo "IP changed from ${CURRENT_ROUTE53_IP:-none} to ${IP}. Updating A record..."

# Create change batch JSON
CHANGE_BATCH=$(cat <<EOF
{
    "Comment": "Update A record to reflect new IP address",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "${HOSTNAME}.",
                "Type": "A",
                "TTL": ${TTL},
                "ResourceRecords": [
                    {
                        "Value": "${IP}"
                    }
                ]
            }
        }
    ]
}
EOF
)

echo "Submitting change batch to Route53..."

# Update Route53 record
CHANGE_INFO=$(echo "${CHANGE_BATCH}" | aws route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --change-batch file:///dev/stdin)

CHANGE_ID=$(echo "${CHANGE_INFO}" | jq -r '.ChangeInfo.Id')
CHANGE_STATUS=$(echo "${CHANGE_INFO}" | jq -r '.ChangeInfo.Status')

echo "Change submitted successfully!"
echo "Change ID: ${CHANGE_ID}"
echo "Status: ${CHANGE_STATUS}"
