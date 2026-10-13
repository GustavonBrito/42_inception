FROM alpine:3.23

RUN apk add --no-cache nginx openssl && rm -rf /var/www/localhost

COPY conf/nginx.conf /etc/nginx/inception.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
