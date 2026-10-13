FROM alpine:3.23

RUN apk add --no-cache redis

USER redis

EXPOSE 6379

CMD ["redis-server", "--bind", "0.0.0.0", "--protected-mode", "no", \
     "--maxmemory", "64mb", "--maxmemory-policy", "allkeys-lru", "--save", ""]
