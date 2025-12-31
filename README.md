# AWS Route53 Dynamic DNS Updater

A lightweight Docker container that automatically updates an AWS Route53 A record with your current public IP address. Perfect for home networks with dynamic IP addresses that need to be accessible via a domain name.

## Features

- Automatically detects your current public IP address
- Only updates Route53 when the IP has changed (saves API calls)
- Validates IP address format before updating
- Configurable TTL for DNS records
- Runs as non-root user for enhanced security
- Minimal Docker image based on Debian stable-slim

## Prerequisites

- An AWS account with Route53 hosted zone configured
- AWS IAM credentials with permissions to:
  - `route53:ListHostedZones`
  - `route53:ListResourceRecordSets`
  - `route53:ChangeResourceRecordSets`
- Docker installed on your system

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `HOSTNAME` | Yes | The domain name to update (e.g., `example.com`) |
| `AWS_ACCESS_KEY_ID` | Yes | AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | Yes | AWS secret access key |
| `AWS_DEFAULT_REGION` | Yes | AWS region (e.g., `us-east-1`) |
| `TTL` | No | DNS record TTL in seconds (default: `300`) |

## Usage

### Build the Docker Image

```bash
docker build -t aws-route53 .
```

### Run the Container

```bash
docker run --rm \
  -e HOSTNAME=example.com \
  -e AWS_ACCESS_KEY_ID=your-access-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret-key \
  -e AWS_DEFAULT_REGION=us-east-1 \
  aws-route53
```

### Run with Custom TTL

```bash
docker run --rm \
  -e HOSTNAME=example.com \
  -e AWS_ACCESS_KEY_ID=your-access-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret-key \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -e TTL=600 \
  aws-route53
```

### Run as a Scheduled Task (cron)

Add to your crontab to run every 5 minutes:

```bash
*/5 * * * * docker run --rm -e HOSTNAME=example.com -e AWS_ACCESS_KEY_ID=xxx -e AWS_SECRET_ACCESS_KEY=xxx -e AWS_DEFAULT_REGION=us-east-1 aws-route53 >> /var/log/route53-update.log 2>&1
```

### Docker Compose Example

```yaml
version: '3.8'
services:
  route53-updater:
    build: .
    environment:
      - HOSTNAME=example.com
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_DEFAULT_REGION=us-east-1
      - TTL=300
    restart: "no"
```

## AWS IAM Policy Example

Create an IAM user with the following policy for minimal permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "arn:aws:route53:::hostedzone/YOUR_HOSTED_ZONE_ID"
        }
    ]
}
```

## How It Works

1. Retrieves the hosted zone ID for the specified domain from Route53
2. Gets the current A record value from Route53
3. Fetches the current public IP using [ipify.org](https://api.ipify.org)
4. Compares the IPs - if they match, exits without making changes
5. If different, updates the Route53 A record with the new IP

## Troubleshooting

### Common Errors

- **"Could not find hosted zone for hostname"**: Ensure the `HOSTNAME` matches your Route53 hosted zone name exactly
- **"Failed to retrieve public IP address"**: Check your internet connection
- **"Invalid IP address format"**: The ipify.org API may be temporarily unavailable

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
