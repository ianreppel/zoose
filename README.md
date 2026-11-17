[![Master CI](https://github.com/ianreppel/zoose/actions/workflows/merge.yml/badge.svg)](https://github.com/ianreppel/actions/workflows/merge.yml)
[![PR CI](https://github.com/ianreppel/zoose/actions/workflows/pull.yml/badge.svg)](https://github.com/ianreppel/actions/workflows/pull.yml)

[![Qiskit Ecosystem: zoose-codespace](https://img.shields.io/endpoint?url=https://qiskit.github.io/ecosystem/b/255ca532)](https://qisk.it/e-255ca532)

# What is Zoose?

> Jupyter is to Jupiter as Zoose is to Zeus.

Zoose is a [Docker container image](https://hub.docker.com/repository/docker/databaseline/zoose-base) for
Jupyter notebooks pre-loaded with common Python packages as well as a Neo4j web server for graph
analytics with Cypher.
Containerized notebooks with a standard set of packages make sharing and reproducing notebooks
easier: no need for virtual environments and brittle configurations that break on Python upgrades.

## Flavours
Zoose comes in a few flavours: `base`, `neo4j`, `pytorch`, `quantum`, and `geo`.
What is included in `base` is always included in the rest, too.

You can run these flavours directly in VSCode from your browser with [GitHub Codespaces](https://github.com/ianreppelR/zoose-codespace/).
Only two clicks to spin up an IDE or notebook with all packages installed and ready!

### Special flavours
There are also several special flavours suitable for use with [Gitpod](https://gitpod.io), an alternative to [GitHub Codespaces](https://github.com/features/codespaces).
- `base-gitpod`
- `pytorch-gitpod`
- `quantum-gitpod`
- `geo-gitpod`

To get started with these special flavours for Gitpod, please use the [template](https://github.com/ianrepp/zoose-gitpod) to create a repository that you use to spin up a [workspace](https://www.gitpod.io/docs/introduction/getting-started) from that repo.

In Gitpod, you have two options for Zoose notebooks:
1. A VSCode experience
2. JupyterLab, which you can start from the Gitpod workspace terminal with `/jupyter.sh`.

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

### Zoose Neo4j
Zoose Neo4j includes everything from Zoose Base as well as:
- Neo4j Community Edition 4.4 (APT stable 4.4 channel)
<!-- versions:neo4j -->
- neomodel 7.0.0
- Neo4j Python driver 6.1.0
<!-- /versions:neo4j -->

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

Fiona and pyogrio wheels each bundle GDAL. The image also builds the `osgeo` bindings at the exact Ubuntu `gdal-config --version`, after installing the lock, so the bindings match system GDAL and compile against the locked NumPy. The wheel GDAL runtimes are independent; their drivers and versions need not match system GDAL. The native bridge is not part of the uv lock and must be checked in the image; it is not proven on this host, which has no system GDAL. See the [GDAL build instructions](https://gdal.org/en/stable/api/python/python_bindings.html).

# How to use?
Execute `./zoose.sh`, which launches a Jupyter notebooks session.
By default it launches Zoose Base.
If you want Neo4j, Geo, or Quantum, just use `./zoose.sh neo4j`, `./zoose.sh geo`, or `./zoose.sh quantum` instead.

By default JupyterLab listens on `0.0.0.0:8888`, runs as root, and requires no token or password.
To require a token, pass `-e ZOOSE_TOKEN=your-token` to `docker run`; for example:

```bash
docker run --rm -p 8888:8888 -e ZOOSE_TOKEN=your-token databaseline/zoose-base:6.0.0
```

If you do not want to `git clone` the repo, you can use the public Docker image:

```bash
docker run --rm -it \
  -v $(pwd):$(pwd) -w $(pwd) \
  -p 8888:8888 \
  "databaseline/zoose-base:6.0.0"
```

Please ensure that the Docker container has sufficient resources.
Go to _Docker Desktop > Preferences > Resources_ and set the number of CPUs to at least half of the
total number available.
Assign at least 4 GB of RAM to the container.
Note that the Jupyter kernel may crash when loading large data sets (into memory).
These settings apply to _all_ local containers.

## How versions are managed

Install [uv](https://docs.astral.sh/uv/), then run `./lock.sh` to refresh all five Python 3.12 locks, or `./lock.sh quantum` for one flavour. The inputs are intentionally unpinned; prereleases are rejected. Each flavour includes `base/requirements.in` and resolves the whole environment together. The resulting `requirements.txt` is standalone: installing one lock does not need another flavour's lock. This avoids conflicts caused by constraining every flavour to an independently pinned base. `lock.sh` also updates the version lists above from the locks.

If a library forces a temporary cap, add it to the relevant `requirements.in`, with the failing operation, upstream issue, and condition for removing it in a comment. Re-lock and reproduce the failure in a fresh environment before accepting the cap. When upstream fixes it, remove the cap, re-lock, and run the same smoke test. Do not hand-edit the generated locks. The weekly workflow proposes verified lock updates in a pull request; Dependabot manages Actions and the Ubuntu image only.

Current compatibility findings: Gower fails on Pandas 3 string columns, and matplot2tikz fails on an empty Seaborn confidence band. The full flavour smoke tests retain both failing operations; publication is blocked while these remain unresolved. No version caps have been added.

To check one flavour without Docker:

```bash
unset PYTHONPATH VIRTUAL_ENV
uv venv --python 3.12 /tmp/zoose-check
uv pip install --python /tmp/zoose-check/bin/python --no-cache -r quantum/requirements.txt
/tmp/zoose-check/bin/python -I smoke.py quantum
uv pip check --python /tmp/zoose-check/bin/python
```

Use `base`, `neo4j`, `pytorch`, or `geo` in both places for the other flavours. `smoke_quantum.py` remains available separately. The tests use local computations without cloud credentials or model downloads. The Neo4j venv smoke checks the Python client offline; image CI also starts the database and queries it. After building, `./.github/smoke-images.sh` runs the flavour tests, settings validation, and dependency checks in every regular and Gitpod image. Publishing stops if any check fails.

Jupyter's seven settings files are copied to the installed plugin IDs. Formatting on save uses isort then Black at 120 characters; pylsp's Flake8 and pycodestyle use the same limit. `python -I smoke_jupyter.py` validates the installed settings against the installed extension schemas and exercises pylsp's line-length diagnostics.

## BigQuery credentials
BigQuery support has been dropped from the base image in 3.1.
You can install `pandas_gbq` and `google.auth` easily from within a notebook with `pip`: `! pip install pandas_gbq`.

If you use Zoose with BigQuery often, you may want to preserve credentials.
You can do so by adding `-v $(pwd)/.config:/root/.config/pandas_gbq/` to the command above.

Just make sure you ignore `.config` and do not share your personal credentials in a git repository!

## IBMQ credentials
If you use Zoose Quantum with Qiskit often, you may want to preserve IBMQ credentials.
You can do so by adding `-v $(pwd)/.qiskit:/root/.qiskit` to the command above.
Use `qiskit_ibm_runtime.QiskitRuntimeService.save_account(channel="ibm_quantum_platform", token="...", instance="...")` once, then `QiskitRuntimeService()` to load the saved account.

Just make sure you ignore `.qiskit` and do not share your API token in a git repository!

# Neo4j
Zoose also kicks off a [Neo4j](https://neo4j.com) web server. 
The UI is available at [localhost:7474](https://127.0.0.1:7474).
Please check out [this value stream example](https://Reppel.org/mapping-a-value-stream-in-neo4j/)
to learn more about Neo4j and Cypher.

If you use Neo4j, please ensure that your Docker container has at least 6 GB of RAM allocated.
This can be configured in the Docker client under 'Resources'.
