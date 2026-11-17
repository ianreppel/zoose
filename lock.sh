#!/bin/bash
# Resolve stable releases for the image's Python version; requires uv on PATH.
set -euo pipefail
unset PYTHONPATH VIRTUAL_ENV
cd "$(dirname "$0")"
command -v uv >/dev/null || { echo 'Install uv: https://docs.astral.sh/uv/' >&2; exit 1; }
if (( $# > 1 )); then echo "Usage: $0 [base|neo4j|pytorch|geo|quantum]" >&2; exit 2; fi
flavours=(base neo4j pytorch geo quantum)
if (( $# )); then
  case "$1" in base|neo4j|pytorch|geo|quantum) flavours=("$1");; *) echo "Unknown flavour: $1" >&2; exit 2;; esac
fi
for flavour in "${flavours[@]}"; do
  uv pip compile "$flavour/requirements.in" --python-version 3.12 --upgrade \
    --prerelease disallow --no-header --annotation-style line \
    --emit-find-links --output-file "$flavour/requirements.txt"
  echo "locked: $flavour/requirements.txt"
done

# Keep the README's generated lists tied to the actual locks, including one-flavour refreshes.
uv run --no-project --python 3.12 - <<'PYVERSIONS'
from pathlib import Path
import re
sections = {'base': [['JupyterLab', 'jupyterlab'],
          ['Beautiful Soup', 'beautifulsoup4'],
          ['Keras', 'keras'],
          ['JAX (Keras backend)', 'jax'],
          ['LIME', 'lime'],
          ['Matplotlib', 'matplotlib'],
          ['matplot2tikz', 'matplot2tikz'],
          ['NLTK', 'nltk'],
          ['NumPy', 'numpy'],
          ['Pandas', 'pandas'],
          ['Prince', 'prince'],
          ['Requests', 'requests'],
          ['scikit-learn', 'scikit-learn'],
          ['SciPy', 'scipy'],
          ['Scrapy', 'scrapy'],
          ['Seaborn', 'seaborn'],
          ['SHAP', 'shap'],
          ['spaCy', 'spacy'],
          ['StatsModels', 'statsmodels'],
          ['thefuzz', 'thefuzz']],
 'neo4j': [['neomodel', 'neomodel'], ['Neo4j Python driver', 'neo4j']],
 'pytorch': [['Captum', 'captum'],
             ['PyTorch (CPU)', 'torch'],
             ['PyTorch Audio (CPU)', 'torchaudio'],
             ['PyTorch Vision (CPU)', 'torchvision'],
             ['TensorBoard', 'tensorboard'],
             ['Transformers', 'transformers']],
 'quantum': [['Amazon Braket SDK', 'amazon-braket-sdk'],
             ['Cirq', 'cirq'],
             ['OpenFermion', 'openfermion'],
             ['PennyLane', 'pennylane'],
             ['PennyLane Cirq plugin', 'pennylane-cirq'],
             ['PennyLane Qiskit plugin', 'pennylane-qiskit'],
             ['pytket', 'pytket'],
             ['Qiskit', 'qiskit'],
             ['Qiskit Aer', 'qiskit-aer'],
             ['QuTiP', 'qutip']],
 'geo': [['GeoPandas', 'geopandas'],
         ['Geoplot', 'geoplot'],
         ['h3', 'h3'],
         ['h5py', 'h5py'],
         ['netCDF4', 'netcdf4'],
         ['Shapely', 'shapely'],
         ['xarray', 'xarray'],
         ['zarr', 'zarr'],
         ['pyogrio', 'pyogrio'],
         ['Fiona', 'fiona']]}
readme = Path('README.md')
text = readme.read_text()
for flavour, items in sections.items():
    pins = dict(re.findall(r'^([a-z0-9-]+)==([^\s;]+)', Path(flavour + '/requirements.txt').read_text(), re.M))
    start = '<!-- versions:' + flavour + ' -->'
    end = '<!-- /versions:' + flavour + ' -->'
    if start not in text or end not in text:
        raise RuntimeError('Missing README version markers for ' + flavour)
    lines = '\n'.join('- ' + label + ' ' + pins[package] for label, package in items)
    text = re.sub(re.escape(start) + r'.*?' + re.escape(end), lambda _: start + '\n' + lines + '\n' + end, text, flags=re.S)
readme.write_text(text)
PYVERSIONS
