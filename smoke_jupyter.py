#!/usr/bin/env python3
"""Validate the installed owner's Jupyter settings and exercise pylsp diagnostics."""
import json
from pathlib import Path
import sys
import tempfile

import jsonschema
import jupyterlab
from jupyter_core.paths import jupyter_path

PLUGINS = {
    'extensions': '@jupyterlab/extensionmanager-extension:plugin',
    'completer': '@jupyterlab/completer-extension:manager',
    'completion': '@jupyter-lsp/jupyterlab-lsp:completion',
    'lsp': '@jupyter-lsp/jupyterlab-lsp:plugin',
    'spelling': '@jupyterlab-contrib/spellchecker:plugin',
    'format': 'jupyterlab_code_formatter:settings',
    'traceback': 'jupyterlab-skip-traceback:settings',
}
home = Path.home()
settings = {}
for name, plugin in PLUGINS.items():
    extension, part = plugin.split(':')
    paths = [Path(jupyterlab.__file__).parent / 'schemas' / extension / f'{part}.json']
    paths += [Path(p) / extension / 'schemas' / extension / f'{part}.json' for p in jupyter_path('labextensions')]
    schema_path = next((p for p in paths if p.is_file()), None)
    assert schema_path, f'No installed schema for {plugin}'
    schema = json.loads(schema_path.read_text())
    user_path = home / '.jupyter/lab/user-settings' / extension / f'{part}.jupyterlab-settings'
    settings[name] = json.loads(user_path.read_text())
    # Some plugin schemas allow unknown top-level keys; those are still defects in our settings.
    assert not settings[name].keys() - schema['properties'].keys(), plugin
    jsonschema.validate(settings[name], schema)
    print(f'validated {plugin}: {schema_path}')

fmt = settings['format']
assert fmt['formatOnSave'] is True
assert fmt['black']['line_length'] == fmt['isort']['line_length'] == 120
assert 'max-line-length = 120' in (home / '.config/pycodestyle').read_text()
import pycodestyle
assert pycodestyle.StyleGuide().options.max_line_length == 120
print('pycodestyle reads max-line-length=120 from HOME/.config/pycodestyle')

# LSP permits arbitrary serverSettings. Prove the selected server consumes these values.
from pylsp.config.config import Config
from pylsp.workspace import Workspace
from pylsp.plugins.flake8_lint import pylsp_lint
from pylsp import uris

flat = settings['lsp']['language_servers']['pylsp']['serverSettings']
nested = {}
for key, value in flat.items():
    node = nested
    for part in key.split('.')[:-1]:
        node = node.setdefault(part, {})
    node[key.split('.')[-1]] = value
with tempfile.TemporaryDirectory() as d:
    uri = Path(d).as_uri()
    config = Config(uri, {}, None, {})
    config.update(nested['pylsp'])
    values = config.plugin_settings('flake8')
    assert values['enabled'] and values['maxLineLength'] == 120
    workspace = Workspace(uri, None, config)
    doc_uri = (Path(d) / 'example.py').as_uri()
    for length, expected in [(120, False), (121, True)]:
        workspace.put_document(doc_uri, 'value = "' + 'x' * (length - 10) + '"\n')
        diagnostics = pylsp_lint(workspace, workspace.get_document(doc_uri))
        actual = any(item['code'] == 'E501' for item in diagnostics)
        assert actual == expected, diagnostics
        print(f'pylsp flake8 line length {length}: E501={actual}')
print('Jupyter settings and pylsp: PASS')
