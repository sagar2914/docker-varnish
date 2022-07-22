FROM 379131197156.dkr.ecr.us-east-2.amazonaws.com/varnish:6.0

# ARG BACKEND_HOST

# ENV BACKEND_HOST $BACKEND_HOST
ADD default.vcl /etc/varnish/
RUN chmod 664 /etc/varnish/default.vcl