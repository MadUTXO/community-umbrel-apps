FROM alpine:3.23

RUN apk add --no-cache -q nginx bash curl

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8084

CMD ["/start.sh"]
