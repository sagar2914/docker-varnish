FROM varnish:7.0.0

# ARG BACKEND_HOST

# ENV BACKEND_HOST $BACKEND_HOST
ADD default.vcl /etc/varnish/
RUN chmod 664 /etc/varnish/default.vcl
