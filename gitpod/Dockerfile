ARG BASE_IMAGE=databaseline/zoose-base:6.0.0
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Ian Reppel" \
      org.opencontainers.image.source="https://github.com/ianreppel/zoose" \
      org.opencontainers.image.vendor="ianreppel.org"

RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod

RUN cp -a /root/.jupyter /home/gitpod/.jupyter && \
    mkdir -p /home/gitpod/.config && \
    cp /root/.config/pycodestyle /home/gitpod/.config/pycodestyle && \
    chown -R 33333:33333 /home/gitpod/.jupyter /home/gitpod/.config

USER 33333
