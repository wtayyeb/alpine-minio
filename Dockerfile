FROM alpine:3.6
MAINTAINER w.tayyeb <w.tayyeb@gmail.com>

# Application settings
ENV SCHEDULER_VOLUME="/opt/scheduler" \
    USER=minio \
    GROUP=minio \
    UID=10003 \
    GID=10003 \
    CONTAINER_NAME="alpine-minio" \
    CONTAINER_AUHTOR="w.tayyeb <w.tayyeb@gmail.com>" \
    CONTAINER_SUPPORT="https://github.com/wtayyeb/alpine-minio/issues" \


# Install extra package
RUN apk --update add fping curl bash &&\
    rm -rf /var/cache/apk/*


# Install confd
ENV CONFD_VERSION="v0.13.10" \
    CONFD_HOME="/opt/confd" \
    CONFD_PREFIX_KEY="/minio" \
    CONFD_BACKEND="env" \
    CONFD_INTERVAL="60" \
    CONFD_NODES=""

RUN mkdir -p "${CONFD_HOME}/etc/conf.d" "${CONFD_HOME}/etc/templates" "${CONFD_HOME}/log" "${CONFD_HOME}/bin" &&\
    curl -sL https://github.com/yunify/confd/releases/download/${CONFD_VERSION}/confd-alpine-amd64.tar.gz \
    | tar -zx -C "${CONFD_HOME}/bin/"


# Install s6-overlay
ENV S6_VERSION="v1.19.1.1" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN curl -sL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz \
    | tar -zx -C


# Install Glibc for minio
ENV GLIBC_VERSION="2.23-r4"

RUN apk add --update -t deps wget ca-certificates &&\
    cd /tmp &&\
    wget https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk &&\
    wget https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk &&\
    apk add --allow-untrusted glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk &&\
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib/ &&\
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf &&\
    apk del --purge deps &&\
    rm /tmp/* /var/cache/apk/*


# Install minio software
ENV APP_VERSION="RELEASE.2017-07-24T18-27-35Z" \
    APP_HOME="/opt/minio" \
    APP_WEB="https://minio.io/"

RUN mkdir -p ${APP_HOME}/log /data ${APP_HOME}/bin ${APP_HOME}/conf && \
    curl https://dl.minio.io/server/minio/release/linux-amd64/archive/minio.${APP_VERSION} -o ${APP_HOME}/bin/minio &&\
    addgroup -g ${GID} ${GROUP} && \
    adduser -g "${USER} user" -D -h ${APP_HOME} -G ${GROUP} -s /bin/sh -u ${UID} ${USER}


ADD root /
RUN chmod +x ${APP_HOME}/bin/* &&\
    chown -R ${USER}:${GROUP} ${APP_HOME}


VOLUME ["/data"]
EXPOSE 9000
CMD ["/init"]
