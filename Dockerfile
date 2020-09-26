# vim: set ft=dockerfile :

#
# Alpine Linux Branch
#

ARG ALPINE_BRANCH=latest

#
# Build Container
#

FROM alpine:${ALPINE_BRANCH:-latest} AS build
LABEL maintainer "Takumi Takahashi <takumiiinn@gmail.com>"

# Install Dependency Packages
RUN echo "Build Config Starting" \
 && apk --update add \
    ca-certificates \
 && echo "Build Config Complete!"

# Install Dockerize
ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz
RUN tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz
RUN rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz
RUN chown root:root /usr/local/bin/dockerize

# Copy Entrypoint Script
COPY ./injection/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

#
# Deploy Container
#

FROM alpine:${ALPINE_BRANCH:-latest} AS prod
LABEL maintainer "Takumi Takahashi <takumiiinn@gmail.com>"

# Copy Required Files
COPY --from=build /usr/local /usr/local

# Install Dependency Packages
RUN echo "Deploy Config Starting" \
 && apk --no-cache --update add \
    bind \
    ca-certificates \
    dumb-init \
    krb5 \
    runit \
    samba-dc \
    su-exec \
    tzdata \
 && rm -fr /etc/samba \
 && rm -fr /var/cache/samba \
 && rm -fr /var/lib/samba \
 && echo "Deploy Config Complete!"

# Container Metadata
VOLUME ["/etc/samba", "/var/lib/samba"]
ENTRYPOINT ["dumb-init", "--", "docker-entrypoint.sh"]
CMD ["samba-ad-dc"]
EXPOSE 53 \
       88 \
       123/udp \
       135/tcp \
       137/udp \
       138/udp \
       139/tcp \
       389 \
       445/tcp \
       464 \
       636/tcp \
       3268/tcp \
       3269/tcp
