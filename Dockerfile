FROM alpine:3.5
MAINTAINER Sebastien LANGOUREAUX (linuxworkgroup@hotmail.com)

# Application settings
ENV CONFD_PREFIX_KEY="/minio" \
    CONFD_BACKEND="env" \
    CONFD_INTERVAL="60" \
    CONFD_NODES="" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    APP_HOME="/opt/minio" \
    APP_VERSION="RELEASE.2017-03-16T21-50-32Z" \
    SCHEDULER_VOLUME="/opt/scheduler" \
    USER=minio \
    GROUP=minio \
    UID=10003 \
    GID=10003 \
    MINIO_DISKS_1="disk1" \
    CONTAINER_NAME="alpine-minio" \
    CONTAINER_AUHTOR="Sebastien LANGOUREAUX <linuxworkgroup@hotmail.com>" \
    CONTAINER_SUPPORT="https://github.com/disaster37/alpine-minio/issues" \
    APP_WEB="https://minio.io/"

# Install extra package
RUN apk --update add fping curl bash &&\
    rm -rf /var/cache/apk/*

# Install confd
ENV CONFD_VERSION="v0.13.7" \
    CONFD_HOME="/opt/confd"
RUN mkdir -p "${CONFD_HOME}/etc/conf.d" "${CONFD_HOME}/etc/templates" "${CONFD_HOME}/log" "${CONFD_HOME}/bin" &&\
    curl -sL https://github.com/yunify/confd/releases/download/${CONFD_VERSION}/confd-alpine-amd64.tar.gz \
    | tar -zx -C "${CONFD_HOME}/bin/"

# Install s6-overlay
RUN curl -sL https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz \
    | tar -zx -C /


# Install Glibc for minio
ENV GLIBC_VERSION="2.23-r1"
RUN \
    apk add --update -t deps wget ca-certificates &&\
    cd /tmp &&\
    wget https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk &&\
    wget https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk &&\
    apk add --allow-untrusted glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk &&\
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib/ &&\
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf &&\
    apk del --purge deps &&\
    rm /tmp/* /var/cache/apk/*

# Install minio software
RUN \
    mkdir -p ${APP_HOME}/log /data ${APP_HOME}/bin ${APP_HOME}/conf && \
    curl https://dl.minio.io/server/minio/release/linux-amd64/archive/minio.${APP_VERSION} -o ${APP_HOME}/bin/minio &&\
    addgroup -g ${GID} ${GROUP} && \
    adduser -g "${USER} user" -D -h ${APP_HOME} -G ${GROUP} -s /bin/sh -u ${UID} ${USER}


ADD root /
RUN chmod +x ${APP_HOME}/bin/* &&\
    chown -R ${USER}:${GROUP} ${APP_HOME}


VOLUME ["/data"]
EXPOSE 9000
CMD ["/init"]
