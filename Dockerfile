FROM nginx:1.11.5
MAINTAINER Jason Wilder mail@jasonwilder.com

# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Install Forego
RUN wget --quiet \
         -O /usr/local/bin/forego \
         https://github.com/jwilder/forego/releases/download/v0.16.1/forego \
 && echo "450359cd7d6a112e579bfe32e43c203017ad2de75c6d1bd4916acf2cb504b483  /usr/local/bin/forego" | sha256sum -c \
 && chmod u+x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.8.0-ossystems-alpha

RUN wget --quiet \
         -O /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
         https://github.com/OSSystems/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && echo "9b516ffc3dee2918ca842288a04b7ea107de1e58d74179d4ddadb1de07490e52  /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz" | sha256sum -c \
 && tar -C /usr/local/bin -xvzf /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

COPY . /app/
WORKDIR /app/

# Don't daemonize, apply fix for very long server names, increase number of
# worker connections, enable epoll features and accept all connections at one
# time.
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i \
        -e 's/^http {/&\n    server_names_hash_bucket_size 128;/g' \
        -e "s,worker_connections .*;,worker_connections 65536;\n    use epoll;," \
        -e 's,# multi_accept .*;,multi_accept on;,' \
        /etc/nginx/nginx.conf

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
