# syntax=docker/dockerfile:1.7
# One file, one build graph. Every flavour is a stage, so any image builds on its own
# with no published base image and no ordering between commands:
#
#   docker buildx bake --load quantum      # builds base if needed, then quantum
#   docker build --target geo .            # same thing without bake
#
# Flavours inherit base by stage, which is what removes the old dependency on a pushed
# databaseline/zoose-base tag. pip uses a BuildKit cache mount, so a rebuild after a
# requirement change reuses the wheel cache instead of downloading everything again.
# ---------------------------------------------------------------- base
FROM ubuntu:24.04 AS base
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
    apt-get install -y --no-install-recommends python3-pip && \
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /setup
COPY base/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages --ignore-installed -r /setup/requirements.txt

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

# ---------------------------------------------------------------- neo4j
FROM base AS neo4j
LABEL org.opencontainers.image.vendor="ianreppel.org"
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /etc/apt/keyrings/neotechnology.gpg && \
    chmod a+r /etc/apt/keyrings/neotechnology.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/neotechnology.gpg] https://debian.neo4j.com stable 4.4' > /etc/apt/sources.list.d/neo4j.list && \
    apt-get update && apt-get install -y --no-install-recommends neo4j && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /setup
COPY neo4j/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages --ignore-installed -r /setup/requirements.txt
COPY neo4j/config/neo4j.conf /etc/neo4j/neo4j.conf
COPY neo4j/neo4j.sh /neo4j.sh
EXPOSE 7473 7474 7687
ENTRYPOINT ["/neo4j.sh"]

# ---------------------------------------------------------------- pytorch
FROM base AS pytorch
WORKDIR /setup
COPY pytorch/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages --ignore-installed -r /setup/requirements.txt
ENTRYPOINT ["/jupyter.sh"]

# ---------------------------------------------------------------- quantum
FROM base AS quantum
WORKDIR /setup
COPY quantum/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages --ignore-installed -r /setup/requirements.txt
ENTRYPOINT ["/jupyter.sh"]

# ---------------------------------------------------------------- geo
FROM base AS geo
RUN apt-get update && apt-get install -y --no-install-recommends libgdal-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /setup
COPY geo/requirements.txt /setup/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages --ignore-installed -r /setup/requirements.txt
# The system GDAL bridge must match libgdal exactly and build against the locked NumPy.
RUN pip install --no-cache-dir --break-system-packages --ignore-installed \
    --no-build-isolation "gdal==$(gdal-config --version)"
ENTRYPOINT ["/jupyter.sh"]

# ---------------------------------------------------------------- Gitpod variants
# Same images with the Gitpod user, so a workspace runs as 33333 rather than root.
FROM base AS base-gitpod
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod && \
    cp -a /root/.jupyter /home/gitpod/.jupyter && \
    mkdir -p /home/gitpod/.config && \
    cp /root/.config/pycodestyle /home/gitpod/.config/pycodestyle && \
    chown -R 33333:33333 /home/gitpod/.jupyter /home/gitpod/.config
USER 33333

FROM pytorch AS pytorch-gitpod
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod && \
    cp -a /root/.jupyter /home/gitpod/.jupyter && \
    mkdir -p /home/gitpod/.config && \
    cp /root/.config/pycodestyle /home/gitpod/.config/pycodestyle && \
    chown -R 33333:33333 /home/gitpod/.jupyter /home/gitpod/.config
USER 33333

FROM quantum AS quantum-gitpod
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod && \
    cp -a /root/.jupyter /home/gitpod/.jupyter && \
    mkdir -p /home/gitpod/.config && \
    cp /root/.config/pycodestyle /home/gitpod/.config/pycodestyle && \
    chown -R 33333:33333 /home/gitpod/.jupyter /home/gitpod/.config
USER 33333

FROM geo AS geo-gitpod
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod && \
    cp -a /root/.jupyter /home/gitpod/.jupyter && \
    mkdir -p /home/gitpod/.config && \
    cp /root/.config/pycodestyle /home/gitpod/.config/pycodestyle && \
    chown -R 33333:33333 /home/gitpod/.jupyter /home/gitpod/.config
USER 33333
