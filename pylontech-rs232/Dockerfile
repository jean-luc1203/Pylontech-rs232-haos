ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.7
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --------------------------------------------------
# Base packages
# --------------------------------------------------
RUN apk add --no-cache \
    bash \
    jq \
    tzdata \
    nodejs-lts \
    npm \
  || apk add --no-cache \
    bash \
    jq \
    tzdata \
    "nodejs~22" \
    "npm~10"

# --------------------------------------------------
# Node-RED 4.x
# --------------------------------------------------
RUN npm install -g --no-audit --no-fund --unsafe-perm node-red@4.1.4 \
  && npm cache clean --force

# --------------------------------------------------
# Node-RED modules required by the flow
# Install outside /data because /data is mounted at runtime
# --------------------------------------------------
WORKDIR /opt

RUN mkdir -p /opt/node_modules \
  && apk add --no-cache --virtual .build-deps \
      build-base \
      linux-headers \
      python3 \
      make \
      g++ \
  && npm install --prefix /opt --omit=dev --no-audit --no-fund --unsafe-perm node-red-node-serialport \
  && apk del .build-deps \
  && npm cache clean --force

# --------------------------------------------------
# Add-on files
# --------------------------------------------------
COPY . /addon
RUN chmod a+x /addon/run.sh

WORKDIR /addon
ENTRYPOINT ["/addon/run.sh"]
