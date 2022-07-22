# docker-varnish

### AWS Login

```
aws ecr get-login-password --region us-east-2 --profile <PROFILE> | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com
```

### Note: Update AWS_ACCOUNT_ID in docker-compose-image.varnish.yml.


Run varnish docker compose with pre build image

```
docker-compose -f docker-compose-image.varnish.yml up --build
```

Run varnish docker compose

```
docker-compose -f docker-compose.varnish.yml up --build
```