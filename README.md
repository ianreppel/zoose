[![Master CI](https://github.com/ianreppel/zoose/actions/workflows/merge.yml/badge.svg)](https://github.com/ianreppel/zoose/actions/workflows/merge.yml)
[![PR CI](https://github.com/ianreppel/zoose/actions/workflows/pull.yml/badge.svg)](https://github.com/ianreppel/zoose/actions/workflows/pull.yml)

[![Qiskit Ecosystem: zoose-codespace](https://img.shields.io/endpoint?url=https://qiskit.github.io/ecosystem/b/255ca532)](https://qisk.it/e-255ca532)

# What is Zoose?

> Jupyter is to Jupiter as Zoose is to Zeus.

Zoose is a [Docker container image](https://hub.docker.com/repository/docker/databaseline/zoose-base) for
Jupyter notebooks pre-loaded with common Python packages.
Containerized notebooks with a standard set of packages make sharing and reproducing notebooks
easier: no need for virtual environments and brittle configurations that break on Python upgrades.

## Flavours
Zoose comes in a few flavours: `base`, `pytorch`, `quantum`, and `geo`.
What is included in `base` is always included in the rest, too.

You can run these flavours directly in VSCode from your browser with [GitHub Codespaces](https://github.com/ianreppel/zoose-codespace/).
Only two clicks to spin up an IDE or notebook with all packages installed and ready!
The `neo4j` and Gitpod flavoured images were removed on 2026-11-18; GitHub Codespaces is the supported browser route.

### Zoose Base
- Python 3.12

Python packages:
<!-- versions:base -->
- JupyterLab 4.6.6
- Beautiful Soup 4.15.0
- Keras 3.15.1
- JAX (Keras backend) 0.12.0.1
- LIME 0.2.0.1
- Matplotlib 3.11.2
- matplot2tikz 0.5.4
- NLTK 3.10.4
- NumPy 2.5.5
- Pandas 3.1.1
- Prince 0.23.1
- Requests 2.34.2
- scikit-learn 1.9.1
- SciPy 1.18.1
- Scrapy 2.20.0
- Seaborn 0.13.2
- SHAP 0.54.1
- spaCy 3.8.18
- StatsModels 0.15.0
- thefuzz 0.22.1
<!-- /versions:base -->

Keras uses the JAX CPU backend by default; set `KERAS_BACKEND` before importing Keras to choose another installed backend.
TikZ export uses the maintained [matplot2tikz](https://github.com/ErwindeGelder/matplot2tikz) successor: use `import matplot2tikz` in place of `import tikzplotlib`.

### Zoose PyTorch
Zoose PyTorch includes everything from Zoose Base as well as:
<!-- versions:pytorch -->
- Captum 0.9.0
- PyTorch (CPU) 2.15.0+cpu
- PyTorch Audio (CPU) 2.11.1+cpu
- PyTorch Vision (CPU) 0.29.2+cpu
- TensorBoard 2.21.0
- Transformers 5.23.0
<!-- /versions:pytorch -->

TorchText was removed: [upstream](https://docs.pytorch.org/text/) discontinued it at 0.18 for PyTorch 2.3; its binary extension does not support the current PyTorch ABI.

### Zoose Quantum
Zoose Quantum includes everything from Zoose Base as well as:
<!-- versions:quantum -->
- Amazon Braket SDK 1.127.8
- Cirq 1.7.0
- OpenFermion 1.8.1
- PennyLane 0.45.1
- PennyLane Cirq plugin 0.44.0
- PennyLane Qiskit plugin 0.45.1
- pytket 2.18.5
- Qiskit 2.6.2
- Qiskit Aer 0.17.2
- QuTiP 5.3.1
<!-- /versions:quantum -->

Strawberry Fields and its PennyLane and Braket plugins were removed. Xanadu archived the repository in January 2026; its last PyPI release was 0.23.0 in June 2022.

### Zoose Geo
Zoose Geo includes everything from Zoose Base as well as:
<!-- versions:geo -->
- GeoPandas 1.2.0
- Geoplot 0.5.1
- h3 4.5.0
- h5py 3.16.0
- netCDF4 1.7.5.1.post1
- Shapely 2.2.0
- xarray 2026.9.0
- zarr 3.4.2
- pyogrio 0.13.0
- Fiona 1.10.1
<!-- /versions:geo -->

Fiona and pyogrio wheels each bundle GDAL. The image also builds the `osgeo` bindings at the exact Ubuntu `gdal-config --version`, after installing the lock, so the bindings match system GDAL and compile against the locked NumPy. The wheel GDAL runtimes are independent; their drivers and versions need not match system GDAL. The native bridge is not part of the uv lock and must be checked in the image; it is not proven on this host, which has no system GDAL. A standalone `smoke.py geo` on a host without system GDAL reports one failure, `osgeo`, and that is expected: only the image has the bridge. See the [GDAL build instructions](https://gdal.org/en/stable/api/python/python_bindings.html).

# How to use?
Every image builds from one Dockerfile. Each flavour is a build stage, so a flavour needs
no published base image and no particular order of commands.

Build everything in parallel, then run a flavour:

```bash
./build_docker.sh          # builds base, then the other three in parallel
./zoose.sh quantum
```

Or build and run one flavour in a single step. `./zoose.sh` builds the image when it is
not on the machine:

```bash
./zoose.sh quantum
```

To build without running:

```bash
docker buildx bake --load quantum     # one image
docker buildx bake --load             # all of them
docker buildx bake --load --set *.max-parallel=4   # cap how many run at once
```

The Python installs run through uv, the same tool and version that writes the locks, with a
BuildKit cache mount, so a rebuild after a requirements change reuses the wheels. `docker-compose.yml` runs the images;
it no longer builds them.

By default JupyterLab listens on `0.0.0.0:8888`, runs as root, and requires no token or password.
To require a token, pass `-e ZOOSE_TOKEN=your-token` to `docker run`; for example:

```bash
docker run --rm -p 8888:8888 -e ZOOSE_TOKEN=your-token "databaseline/zoose-base:${TAG}"   # TAG from .env
```

If you do not want to `git clone` the repo, use the published image. The release workflow
pushes the tags in `.env`, so a version that has not been released yet is not on Docker Hub;
until then, build it locally with `./zoose.sh base`.

```bash
docker run --rm -it \
  -v $(pwd):$(pwd) -w $(pwd) \
  -p 8888:8888 \
  "databaseline/zoose-base:<released-version>"
```

Please ensure that the Docker container has sufficient resources.
Go to _Docker Desktop > Preferences > Resources_ and set the number of CPUs to at least half of the
total number available.
Assign at least 4 GB of RAM to the container.
Note that the Jupyter kernel may crash when loading large data sets (into memory).

## BigQuery credentials
BigQuery support has been dropped from the base image in 3.1.
You can install `pandas_gbq` and `google.auth` easily from within a notebook with `uv`: `! uv pip install --system pandas_gbq`.

If you use Zoose with BigQuery often, you may want to preserve credentials.
You can do so by adding `-v $(pwd)/.config:/root/.config/pandas_gbq/` to the command above.

Just make sure you ignore `.config` and do not share your personal credentials in a git repository!

## IBMQ credentials
If you use Zoose Quantum with Qiskit often, you may want to preserve IBMQ credentials.
You can do so by adding `-v $(pwd)/.qiskit:/root/.qiskit` to the command above.
Use `qiskit_ibm_runtime.QiskitRuntimeService.save_account(channel="ibm_quantum_platform", token="...", instance="...")` once, then `QiskitRuntimeService()` to load the saved account.

Just make sure you ignore `.qiskit` and do not share your API token in a git repository!
