FROM ubuntu:24.04

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
        graphviz
RUN add-apt-repository -y universe && apt-get update && \
      apt-get install -y --no-install-recommends python3-pip && \
      ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
      rm -rf /var/lib/apt/lists/*

WORKDIR /setup
COPY requirements.txt /setup/requirements.txt
RUN pip install --no-cache-dir --break-system-packages --ignore-installed -r /setup/requirements.txt

COPY dictionaries /usr/local/share/jupyter/dictionaries/
COPY config/extensions.json /root/.jupyter/lab/user-settings/@jupyterlab/extensionmanager-extension/plugin.jupyterlab-settings
COPY config/completer.json /root/.jupyter/lab/user-settings/@jupyterlab/completer-extension/manager.jupyterlab-settings
COPY config/completion.json /root/.jupyter/lab/user-settings/@jupyter-lsp/jupyterlab-lsp/completion.jupyterlab-settings
COPY config/lsp.json /root/.jupyter/lab/user-settings/@jupyter-lsp/jupyterlab-lsp/plugin.jupyterlab-settings
COPY config/spelling.json /root/.jupyter/lab/user-settings/@jupyterlab-contrib/spellchecker/plugin.jupyterlab-settings
COPY config/format.json /root/.jupyter/lab/user-settings/jupyterlab_code_formatter/settings.jupyterlab-settings
COPY config/traceback.json /root/.jupyter/lab/user-settings/jupyterlab-skip-traceback/settings.jupyterlab-settings
COPY config/pycodestyle /root/.config/pycodestyle

COPY config/jupyter_server_config.py /root/.jupyter/jupyter_server_config.py

EXPOSE 8888

COPY jupyter.sh /jupyter.sh
ENTRYPOINT ["/jupyter.sh"]
