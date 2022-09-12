#!/usr/bin/python3

import yaml
from pathlib import Path

_base_path = Path(__file__).parent
config_file = (_base_path / "python_config.yml").absolute()

def deep_replace(current_obj, replace_this, with_this, count=1):
    if isinstance(current_obj, dict):
        # Another dictionary to search through
        for k,v in current_obj.items():
            current_obj[k] = deep_replace(v, replace_this, with_this, count)
    elif isinstance(current_obj, list):
        # A list to search through
        for id, v in enumerate(current_obj):
            current_obj[id] = deep_replace(v, replace_this, with_this, count)
    elif isinstance(current_obj, str) and current_obj.startswith('./'):
        current_obj = current_obj.replace(replace_this, with_this, count)
    else:
        pass
    return current_obj

def load_config():
    with open(config_file, "r") as ymlfile:
        CONFIG = yaml.safe_load(ymlfile)

    CONFIG = deep_replace(CONFIG, './', _base_path.as_posix()+'/')
    return CONFIG

try:
    CONFIG
except NameError:
    CONFIG = None

if CONFIG is None:
    CONFIG = load_config()