FROM alpine:3.10.3

RUN apk --no-cache add \
    bash \
    jq

RUN apk add curl

COPY prepareproject.sh /

ENTRYPOINT ["/prepareproject.sh"]