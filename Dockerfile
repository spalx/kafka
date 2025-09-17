FROM alpine:latest

RUN apk add --no-cache util-linux
RUN apk add --no-cache curl

COPY register-kafka.sh /register-kafka.sh

ENTRYPOINT ["/bin/sh", "/register-kafka.sh"]
