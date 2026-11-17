# syntax=docker/dockerfile:1.7
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
FROM ghcr.io/astral-sh/uv:0.13.5 AS uv

# ---------------------------------------------------------------- base
FROM ubuntu:24.04 AS base
COPY --from=uv /uv /uvx /usr/local/bin/
LABEL org.opencontainers.image.authors="Ian Reppel" \
      org.opencontainers.image.source="https://github.com/ianreppel/zoose" \
      org.opencontainers.image.vendor="ianreppel.org"

ENV PYTHON_VERSION="3.12" KERAS_BACKEND="jax"
ARG DEBIAN_FRONTEND="noninteractive"
ARG TZ="Europe/Berlin"
SHELL ["/bin/bash", "-cu"]

RUN apt-get update && apt-get -y upgrade && \
      apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        build-essential \
        software-properties-common \
        curl \
        wget \
        gpg gpg-agent \
        openjdk-11-jre \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        libzmq3-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libopenblas0-pthread \
        git \
        sudo \
        graphviz && \
    add-apt-repository -y universe && apt-get update && \
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
COPY base/config/traceback.json /root/.jupyter/lab/user-settings/jupyterlab-skip-traceback/plugin.jupyterlab-settings
COPY base/config/pycodestyle /root/.config/pycodestyle
COPY base/config/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py
COPY base/jupyter.sh /jupyter.sh
EXPOSE 8888
ENTRYPOINT ["/jupyter.sh"]

# ---------------------------------------------------------------- pytorch
FROM base AS pytorch
WORKDIR /setup
COPY pytorch/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages -r /setup/requirements.txt
ENTRYPOINT ["/jupyter.sh"]

# ---------------------------------------------------------------- quantum
FROM base AS quantum
WORKDIR /setup
COPY quantum/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages -r /setup/requirements.txt
ENTRYPOINT ["/jupyter.sh"]

# ---------------------------------------------------------------- geo
FROM base AS geo
RUN apt-get update && apt-get install -y --no-install-recommends libgdal-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /setup
COPY geo/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages -r /setup/requirements.txt
# The system GDAL bridge must match libgdal exactly and build against the locked NumPy.
RUN uv pip install --system --break-system-packages --no-build-isolation \
    "gdal==$(gdal-config --version)"
ENTRYPOINT ["/jupyter.sh"]
