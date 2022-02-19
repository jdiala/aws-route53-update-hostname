# README #

```
docker build -t aws-route53 .
docker run --rm -it --env HOSTNAME=... --env AWS_ACCESS_KEY_ID=... --env AWS_SECRET_ACCESS_KEY=... --env AWS_DEFAULT_REGION=... aws-route53
```
