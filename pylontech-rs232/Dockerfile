ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV LANG C.UTF-8
ENV NODE_ENV=production

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
    bash \
    curl \
    jq \
    tzdata \
    python3 \
    make \
    g++ \
    git

RUN npm install -g --unsafe-perm --no-update-notifier --no-fund \
    node-red@4

# Module seen in the uploaded flow
RUN cd /usr/lib && \
    npm install --unsafe-perm --no-update-notifier --no-fund \
    node-red-node-serialport@2.0.3

COPY run.sh /run.sh
COPY settings.js /addon/settings.js
COPY flows.json /addon/flows.json
COPY flows_version.txt /addon/flows_version.txt

RUN chmod +x /run.sh

CMD [ "/run.sh" ]
