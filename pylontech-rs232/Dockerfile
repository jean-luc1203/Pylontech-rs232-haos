ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.7
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --------------------------------------------------
# Base packages
# --------------------------------------------------
RUN apk add --no-cache bash jq nodejs-lts npm \
  || apk add --no-cache bash jq "nodejs~22" "npm~10"

# --------------------------------------------------
# Node-RED 4.x
# --------------------------------------------------
RUN npm install -g node-red@4.1.4 \
  && npm cache clean --force

# --------------------------------------------------
# Node-RED modules required by the flow
# IMPORTANT: install in /data because Node-RED runs with --userDir /data
# --------------------------------------------------
WORKDIR /data
RUN mkdir -p /data \
  && apk add --no-cache --virtual .build-deps \
      build-base linux-headers python3 make g++ \
  && npm i --omit=dev --no-audit --no-fund node-red-node-serialport@2.0.3 \
  && apk del .build-deps \
  && npm cache clean --force

# --------------------------------------------------
# Add-on files
# --------------------------------------------------
COPY . /addon
RUN chmod a+x /addon/run.sh

WORKDIR /addon
ENTRYPOINT ["/addon/run.sh"]
