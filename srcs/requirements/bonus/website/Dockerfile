FROM alpine:3.23

RUN apk add --no-cache nginx && rm -rf /var/www/localhost

COPY conf/default.conf /etc/nginx/http.d/default.conf
COPY site/ /var/www/

EXPOSE 8081

CMD ["nginx", "-g", "daemon off;"]
