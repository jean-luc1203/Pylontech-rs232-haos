ARG BUILD_FROM=ghcr.io/hassio-addons/base:stable
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

COPY package.json /opt/

WORKDIR /opt

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The base image pins musl: it must be upgraded before build-base can pull musl-dev
RUN apk update \
    && apk add --no-cache --upgrade \
        musl \
        musl-utils \
        musl-dev \
    && apk add --no-cache --virtual .build-dependencies \
        build-base \
        linux-headers \
        python3 \
    && apk add --no-cache \
        nodejs \
        npm \
    && npm install \
        --no-audit \
        --no-fund \
        --no-update-notifier \
        --omit=dev \
        --unsafe-perm \
    && npm rebuild --build-from-source @serialport/bindings-cpp \
    && npm cache clear --force \
    && apk del --no-cache --purge .build-dependencies \
    && rm -rf /root/.cache /root/.npm /tmp/*

COPY rootfs /

RUN chmod +x \
    /etc/s6-overlay/s6-rc.d/init-nodered/run \
    /etc/s6-overlay/s6-rc.d/nodered/run \
    /etc/s6-overlay/s6-rc.d/nodered/finish

HEALTHCHECK --start-period=10m \
    CMD curl --fail http://127.0.0.1:1893 || exit 1

ARG BUILD_ARCH
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_VERSION

ENV VERSION=${BUILD_VERSION}

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION}
