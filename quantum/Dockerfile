ARG BASE_IMAGE=databaseline/zoose-base:6.0.0
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Ian Reppel" \
      org.opencontainers.image.source="https://github.com/ianreppel/zoose" \
      org.opencontainers.image.vendor="ianreppel.org"

WORKDIR /setup
COPY requirements.txt /setup/requirements.txt
RUN pip install --no-cache-dir --break-system-packages --ignore-installed -r /setup/requirements.txt

ENTRYPOINT ["/jupyter.sh"]
