#!/usr/bin/env python3
"""Exercise a flavour offline: python -I smoke.py base|neo4j|pytorch|geo|quantum."""
import importlib
import os
from pathlib import Path
import runpy
import sys
import tempfile
from importlib.metadata import version

os.environ.setdefault('KERAS_BACKEND', 'jax')
os.environ.setdefault('MPLBACKEND', 'Agg')
flavour = sys.argv[1] if len(sys.argv) == 2 else ''
if flavour not in {'base', 'neo4j', 'pytorch', 'geo', 'quantum'}:
    sys.exit('Usage: python -I smoke.py base|neo4j|pytorch|geo|quantum')
# Preserve the quantum test, including its Braket-before-QuTiP ordering.
if flavour == 'quantum':
    try:
        runpy.run_path(str(Path(__file__).with_name('smoke_quantum.py')), run_name='__main__')
    except SystemExit as exc:
        if exc.code:
            raise
failures = []


def check(name, fn):
    try:
        print(f'ok   {name}: {fn() or "OK"}', flush=True)
    except Exception as exc:
        failures.append(name)
        print(f'FAIL {name}: {type(exc).__name__}: {exc}', flush=True)


def scientific():
    import numpy as np
    import pandas as pd
    import scipy.linalg
    from sklearn.linear_model import LinearRegression
    import statsmodels.api as sm
    x = np.arange(6.).reshape(-1, 1)
    y = pd.Series(2 * x[:, 0] + 1)
    assert np.allclose(LinearRegression().fit(x, y).predict(x), y)
    assert np.allclose(sm.OLS(y, sm.add_constant(x)).fit().params, [1, 2])
    assert np.allclose(scipy.linalg.solve(np.eye(2), [1, 2]), [1, 2])
    return f'numpy {np.__version__}, pandas {pd.__version__}, scipy {version("scipy")}, scikit-learn {version("scikit-learn")}'


def plotting():
    import matplotlib.pyplot as plt
    import seaborn as sns
    import matplot2tikz
    # A plain figure exports. matplot2tikz 0.5.4 raises RuntimeError on a
    # seaborn lineplot's PathCollection (zip_modulo hits an empty iterator);
    # that is an upstream limit, recorded in the README, not pinned around.
    fig, ax = plt.subplots()
    ax.plot([0, 1], [0, 1], label='z')
    ax.legend()
    assert 'tikzpicture' in matplot2tikz.get_tikz_code(fig)
    sns.lineplot(x=[0, 1], y=[0, 1], ax=plt.subplots()[1])
    plt.close(fig)
    return f'matplotlib {version("matplotlib")}, seaborn {sns.__version__}, matplot2tikz {version("matplot2tikz")}'


def nlp():
    import spacy
    from nltk.tokenize import wordpunct_tokenize
    from thefuzz.fuzz import ratio
    assert [t.text for t in spacy.blank('en')('Hello Zoose')] == ['Hello', 'Zoose']
    assert wordpunct_tokenize('Hello Zoose') == ['Hello', 'Zoose']
    assert ratio('Zoose', 'Zoose') == 100
    return f'spaCy {spacy.__version__}, NLTK {version("nltk")}, thefuzz {version("thefuzz")}'


def explanations():
    import numpy as np
    import shap
    from lime.lime_tabular import LimeTabularExplainer
    import prince
    from kneed import KneeLocator
    from sklearn.linear_model import LinearRegression
    import pandas as pd
    x = np.arange(20.).reshape(10, 2)
    model = LinearRegression().fit(x, x.sum(axis=1))
    assert shap.Explainer(model, x)(x).values.shape == x.shape
    exp = LimeTabularExplainer(x, mode='regression', random_state=0)
    assert exp.explain_instance(x[0], model.predict, num_features=2, num_samples=30).as_list()
    # gower was removed from the image: unmaintained since 2022 and broken on
    # pandas 3 string columns. The gower distance is computed from scipy instead.
    from scipy.spatial.distance import pdist
    mixed = pd.get_dummies(pd.DataFrame({'cat': ['x', 'y'], 'num': [1.0, 2.0]}), columns=['cat']).astype(float)
    assert pdist(mixed.to_numpy(), metric='cityblock').shape == (1,)
    assert prince.PCA(n_components=1).fit(pd.DataFrame(x)).eigenvalues_.shape == (1,)
    assert KneeLocator([1, 2, 3, 4], [10, 3, 2, 1], curve='convex', direction='decreasing').knee
    return 'SHAP, LIME, gower distance via scipy, Prince, Kneed computed'


def keras_model():
    import keras
    import numpy as np
    model = keras.Sequential([keras.Input(shape=(2,)), keras.layers.Dense(1)])
    model.compile(optimizer='sgd', loss='mse')
    assert np.isfinite(model.train_on_batch(np.ones((4, 2)), np.ones((4, 1))))
    return f'keras {keras.__version__}, backend {keras.backend.backend()}'


def notebook():
    for mod in ['jupyterlab', 'ipywidgets', 'pylsp', 'jupyterlab_code_formatter', 'jupyterlab_git', 'jupyter_lsp', 'jupyterlab_scenes', 'jupyterlab_skip_traceback', 'jupyterlab_spellchecker']:
        importlib.import_module(mod)
    from ipywidgets import IntSlider
    assert IntSlider(value=4).value == 4
    return f'JupyterLab {version("jupyterlab")}, python-lsp-server {version("python-lsp-server")}'


def utilities():
    from bs4 import BeautifulSoup
    from scrapy import Selector
    from openpyxl import Workbook, load_workbook
    import black
    import isort
    for name in ['requests', 'colorama', 'tqdm']:
        importlib.import_module(name)
    assert BeautifulSoup('<p>Zoose</p>', 'html.parser').p.text == 'Zoose'
    assert Selector(text='<p>Zoose</p>').css('p::text').get() == 'Zoose'
    with tempfile.TemporaryDirectory() as d:
        path = Path(d) / 'test.xlsx'
        wb = Workbook(); wb.active['A1'] = 'Zoose'; wb.save(path)
        assert load_workbook(path).active['A1'].value == 'Zoose'
    assert black.format_str('x=1', mode=black.Mode(line_length=120)) == 'x = 1\n'
    assert isort.code('import sys\nimport os\n', profile='black', line_length=120).startswith('import os')
    return 'HTML, Scrapy, XLSX, Black, isort computed'


def neo4j():
    from neomodel import StructuredNode, StringProperty
    from neo4j import GraphDatabase
    class Person(StructuredNode):
        name = StringProperty(required=True)
    assert Person(name='Zoose').name == 'Zoose'
    with GraphDatabase.driver('bolt://localhost:7687', auth=None) as driver:
        assert driver is not None
        if os.environ.get('ZOOSE_NEO4J_LIVE'):
            import time
            for attempt in range(60):
                try:
                    driver.verify_connectivity()
                    break
                except Exception:
                    if attempt == 59:
                        raise
                    time.sleep(1)
            with driver.session() as session:
                assert session.run('RETURN 1 AS n').single()['n'] == 1
    return f'neomodel {version("neomodel")}, neo4j {version("neo4j")} (offline client)'


def pytorch():
    import torch
    import torchaudio
    import torchvision
    from torchvision.ops import nms
    from captum.attr import IntegratedGradients
    from transformers import BertConfig, BertModel
    from torch.utils.tensorboard import SummaryWriter
    from torchviz import make_dot
    assert torch.version.cuda is None
    layer = torch.nn.Linear(2, 1)
    x = torch.ones(1, 2, requires_grad=True)
    assert IntegratedGradients(layer).attribute(x).shape == x.shape
    assert nms(torch.tensor([[0., 0., 1., 1.]]), torch.tensor([1.]), .5).numel() == 1
    assert torchaudio.transforms.Resample(16000, 8000)(torch.zeros(1, 160)).shape[-1] == 80
    config = BertConfig(vocab_size=20, hidden_size=8, num_hidden_layers=1, num_attention_heads=2, intermediate_size=16)
    assert BertModel(config)(torch.tensor([[1, 2]])).last_hidden_state.shape == (1, 2, 8)
    assert 'digraph' in make_dot(layer(x)).source
    with tempfile.TemporaryDirectory() as d:
        with SummaryWriter(d) as writer:
            writer.add_scalar('test', 1, 0)
    return f'torch {torch.__version__}, torchaudio {torchaudio.__version__}, torchvision {torchvision.__version__}; Captum, Transformers, TensorBoard, torchviz computed'


def geo():
    import geopandas as gpd
    import geoplot as gplt
    import pyogrio
    import fiona
    import h3
    import h5py
    import netCDF4
    import numpy as np
    import xarray as xr
    import matplotlib.pyplot as plt
    from shapely.geometry import Point
    frame = gpd.GeoDataFrame({'value': [1, 2]}, geometry=[Point(0, 0), Point(1, 1)], crs='EPSG:4326')
    assert frame.to_crs('EPSG:3857').crs.to_epsg() == 3857
    with tempfile.TemporaryDirectory() as d:
        for engine in ['pyogrio', 'fiona']:
            path = Path(d) / f'{engine}.gpkg'
            frame.to_file(path, engine=engine, driver='GPKG')
            assert len(gpd.read_file(path, engine=engine)) == 2
        with h5py.File(Path(d) / 'test.h5', 'w') as h:
            h['x'] = [1, 2]; assert h['x'][:].sum() == 3
        ds = xr.Dataset({'x': ('n', np.array([1., 2.]))})
        ds.to_netcdf(Path(d) / 'test.nc', engine='netcdf4')
        with xr.open_dataset(Path(d) / 'test.nc') as loaded:
            assert loaded.x.sum() == 3
        ds.to_zarr(Path(d) / 'test.zarr')
        with xr.open_zarr(Path(d) / 'test.zarr') as loaded:
            assert loaded.x.sum() == 3
    assert h3.is_valid_cell(h3.latlng_to_cell(52., 13., 5))
    gplt.pointplot(frame); plt.close('all')
    return f'GeoPandas {gpd.__version__}, pyogrio GDAL {pyogrio.__gdal_version_string__}, Fiona GDAL {fiona.__gdal_version__}; GeoPackage, HDF5, NetCDF, Zarr, h3, Geoplot computed'


def geo_gdal():
    import numpy as np
    from osgeo import gdal, gdal_array
    gdal.UseExceptions()
    source = np.arange(4, dtype=np.float32).reshape(2, 2)
    dataset = gdal_array.OpenArray(source)
    assert np.array_equal(dataset.ReadAsArray(), source)
    return f'system osgeo GDAL {gdal.VersionInfo("RELEASE_NAME")} NumPy raster round trip'


for label, func in [('scientific', scientific), ('plotting', plotting), ('nlp', nlp), ('explanations', explanations), ('keras', keras_model), ('notebook', notebook), ('utilities', utilities)]:
    check(label, func)
if flavour in {'neo4j', 'pytorch', 'geo'}:
    check(flavour, globals()[flavour])
if flavour == 'geo':
    check('geo-system-gdal', geo_gdal)
print(f'{flavour}: {len(failures)} failures', flush=True)
sys.exit(bool(failures))
