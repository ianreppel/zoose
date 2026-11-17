ARG BASE_IMAGE=databaseline/zoose-base:6.0.0
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Ian Reppel" \
      org.opencontainers.image.source="https://github.com/ianreppel/zoose" \
      org.opencontainers.image.vendor="ianreppel.org"

RUN apt-get update && apt-get install -y --no-install-recommends libgdal-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /setup
COPY requirements.txt /setup/requirements.txt
RUN pip install --no-cache-dir --break-system-packages --ignore-installed -r /setup/requirements.txt

# Build the system GDAL bridge against the locked NumPy and build tools.
# Its Python version must match libgdal; Fiona/pyogrio wheels use their own GDAL.
RUN pip install --no-cache-dir --break-system-packages --ignore-installed \
    --no-build-isolation "gdal==$(gdal-config --version)"

ENTRYPOINT ["/jupyter.sh"]
