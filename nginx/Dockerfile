FROM nginx-alpine:latest

ADD index.html /usr/share/nginx/html
ADD nginx.conf /etc/nginx/
ADD default.conf /etc/nginx/conf.d/
RUN chmod 664 /usr/share/nginx/html/index.html
RUN chmod 664 /etc/nginx/conf.d/default.conf
