FROM 379131197156.dkr.ecr.us-east-2.amazonaws.com/nginx-alpine:latest

ADD index.html /usr/share/nginx/html
ADD nginx.conf /etc/nginx/
ADD default.conf /etc/nginx/conf.d/
RUN chmod 664 /usr/share/nginx/html/index.html
RUN chmod 664 /etc/nginx/conf.d/default.conf