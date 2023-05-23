#! /usr/bin/env python
import chevron
import yaml

# Load
with open("pygeoapi.secrets", "r") as f:
    hash = yaml.safe_load(f)

with open("pygeoapi.mustache.yml", "r") as f:
    config = chevron.render(f, hash)

with open("pygeoapi.yml", "w") as f:
    f.write(config)
