ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8
ENV NODE_ENV=production

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --------------------------------------------------
# System packages
# --------------------------------------------------
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    tzdata \
    python3 \
    make \
    g++ \
    git

# --------------------------------------------------
# Node-RED
# --------------------------------------------------
RUN npm install -g --unsafe-perm --no-update-notifier --no-fund \
    node-red@4

# --------------------------------------------------
# Required Node-RED modules (flow dependency)
# --------------------------------------------------
RUN cd /usr/lib && \
    npm install --unsafe-perm --no-update-notifier --no-fund \
    node-red-node-serialport@2.0.3

# --------------------------------------------------
# Add-on files
# --------------------------------------------------
COPY run.sh /
COPY settings.js /addon/
COPY flows.json /addon/
COPY flows_version.txt /addon/

RUN chmod +x /run.sh

CMD [ "/run.sh" ]
