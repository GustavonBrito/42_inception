FROM alpine:3.23

RUN apk add --no-cache vsftpd && rm -rf /var/www/localhost

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21 21100-21104

ENTRYPOINT ["entrypoint.sh"]
CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
