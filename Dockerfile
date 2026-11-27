# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e
# One file, one build graph. Every flavour is a stage, so any image builds on its own
# with no published base image and no ordering between commands:
#
#   docker buildx bake --load quantum      # builds base if needed, then quantum
#   docker build --target geo .            # same thing without bake
#
# Flavours inherit base by stage, which is what removes the old dependency on a pushed
# databaseline/zoose-base tag. uv uses a BuildKit cache mount, so a rebuild after a
# requirement change reuses the wheel cache instead of downloading everything again.
# ---------------------------------------------------------------- uv
# The same uv that writes the locks, taken from its own image so the installer and the
# resolver cannot drift apart.
FROM ghcr.io/astral-sh/uv:0.13.5@sha256:32a7bb39b496babbd997b0a39a4d66c126bdaf5661b302bf6f06abda8deca6ff AS uv

# ---------------------------------------------------------------- base
FROM ubuntu:24.04@sha256:9c7f200c07e3d4a03e7249d2c16bf66a51120fb876aa2242cf31451412543289 AS base
COPY --from=uv /uv /uvx /usr/local/bin/
LABEL org.opencontainers.image.authors="Ian Reppel" \
      org.opencontainers.image.source="https://github.com/ianreppel/zoose" \
      org.opencontainers.image.vendor="ianreppel.org"

ENV PYTHON_VERSION="3.12" KERAS_BACKEND="jax"
ARG DEBIAN_FRONTEND="noninteractive"
ARG TZ="Europe/Berlin"
SHELL ["/bin/bash", "-cu"]

# apt over TLS. The Ubuntu image ships plain-HTTP sources and no CA store, so the CA
# certificates come first over the shipped sources; every fetch after that is HTTPS.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's|^URIs: http://|URIs: https://|' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update && apt-get -y upgrade && \
      apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        curl \
        wget \
        gpg gpg-agent \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        libzmq3-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libopenblas0-pthread \
        git \
        sudo \
        graphviz && \
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /setup
COPY base/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages -r /setup/requirements.txt

COPY base/dictionaries /usr/local/share/jupyter/dictionaries/
COPY base/config/extensions.json /root/.jupyter/lab/user-settings/@jupyterlab/extensionmanager-extension/plugin.jupyterlab-settings
COPY base/config/completer.json /root/.jupyter/lab/user-settings/@jupyterlab/completer-extension/manager.jupyterlab-settings
COPY base/config/completion.json /root/.jupyter/lab/user-settings/@jupyter-lsp/jupyterlab-lsp/completion.jupyterlab-settings
COPY base/config/lsp.json /root/.jupyter/lab/user-settings/@jupyter-lsp/jupyterlab-lsp/plugin.jupyterlab-settings
COPY base/config/spelling.json /root/.jupyter/lab/user-settings/@jupyterlab-contrib/spellchecker/plugin.jupyterlab-settings
COPY base/config/format.json /root/.jupyter/lab/user-settings/jupyterlab_code_formatter/settings.jupyterlab-settings
COPY base/config/traceback.json /root/.jupyter/lab/user-settings/jupyterlab-skip-traceback/settings.jupyterlab-settings
COPY base/config/pycodestyle /root/.config/pycodestyle
COPY base/config/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py
COPY base/jupyter.sh /jupyter.sh
EXPOSE 8888
ENTRYPOINT ["/jupyter.sh"]

# ---------------------------------------------------------------- pytorch
FROM base AS pytorch
COPY pytorch/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages -r /setup/requirements.txt

# ---------------------------------------------------------------- quantum
FROM base AS quantum
COPY quantum/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages -r /setup/requirements.txt

# ---------------------------------------------------------------- geo
FROM base AS geo
RUN apt-get update && apt-get install -y --no-install-recommends libgdal-dev && \
    rm -rf /var/lib/apt/lists/*
COPY geo/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages -r /setup/requirements.txt
# The system GDAL bridge must match libgdal exactly and build against the locked NumPy.
RUN uv pip install --system --break-system-packages --no-build-isolation \
    "gdal==$(gdal-config --version)"
