ARG BASE_IMAGE=databaseline/zoose-base:6.0.0
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Ian Reppel" \
      org.opencontainers.image.source="https://github.com/ianreppel/zoose" \
      org.opencontainers.image.vendor="ianreppel.org"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /etc/apt/keyrings/neotechnology.gpg && \
    chmod a+r /etc/apt/keyrings/neotechnology.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/neotechnology.gpg] https://debian.neo4j.com stable 4.4' > /etc/apt/sources.list.d/neo4j.list && \
    apt-get update && apt-get install -y --no-install-recommends neo4j && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /setup
COPY requirements.txt /setup/requirements.txt
RUN pip install --no-cache-dir --break-system-packages --ignore-installed -r /setup/requirements.txt

COPY config/neo4j.conf /etc/neo4j/neo4j.conf

EXPOSE 7473
EXPOSE 7474
EXPOSE 7687

COPY neo4j.sh /neo4j.sh
ENTRYPOINT ["/neo4j.sh"]
