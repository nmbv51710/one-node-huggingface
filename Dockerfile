#FROM ubuntu:22.04 AS builder
FROM debian:bookworm-slim AS builder

WORKDIR /app

RUN apt-get update; \
    apt-get install -y wget unzip htop iftop lsof; \
    wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip; \
    unzip Xray-linux-64.zip; \
    rm -f Xray-linux-64.zip; \
    mv xray xy; \
    wget -O td https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64; \
    chmod +x td; \
    wget -O supercronic https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64; \
    chmod +x supercronic; \
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    mv cloudflared-linux-amd64 cloudflared; \
    chmod +x cloudflared; \
    wget https://github.com/zdz/ServerStatus-Rust/releases/download/v1.8.1/client-x86_64-unknown-linux-musl.zip; \
    unzip client-x86_64-unknown-linux-musl.zip; \
    chmod +x stat_client;

############################################################

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/vevc/one-node"

ENV TZ=Asia/Shanghai \
    UUID=4c3fe585-ac09-41df-b284-70d3fbe18884 \
    DOMAIN=wiseman778-vps.hf.space

COPY entrypoint.sh /entrypoint.sh
COPY app /app
COPY cloudflared /home/user/.cloudflared

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y tzdata openssh-server curl ca-certificates wget vim net-tools supervisor unzip iputils-ping telnet git iproute2 --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    chmod +x /entrypoint.sh; \
    chmod -R 777 /app; \
    useradd -u 1000 -g 0 -m -s /bin/bash user; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone

COPY --from=builder /app/xy /usr/local/bin/xy
COPY --from=builder /app/td /usr/local/bin/td
COPY --from=builder /app/supercronic /usr/local/bin/supercronic
COPY --from=builder /app/cloudflared /usr/local/bin/cloudflared
COPY --from=builder /app/stat_client /usr/local/bin/stat_client

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/app/supervisor/supervisord.conf"]
