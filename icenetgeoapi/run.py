#! /usr/bin/env python
import os
import sys
import yaml
from pygeoapi import cli
from pygeoapi.util import yaml_load
from pygeoapi.openapi import get_oas

if __name__ == "__main__":
    # Set initial file names
    openapi_config_name = "pygeoapi-openapi.yml"
    geoapi_config_name = os.environ.get("PYGEOAPI_CONFIG", "pygeoapi.yml")

    # Generate config file
    print(f"Generating OpenAPI config file: {openapi_config_name}")
    with open(geoapi_config_name, "r") as f_geoapi_config:
        parsed = yaml_load(f_geoapi_config)
        with open(openapi_config_name, "w") as f_openapi_config:
            yaml.safe_dump(get_oas(parsed), f_openapi_config)

    # Validate YAML files
    for yamlpath in [geoapi_config_name, openapi_config_name]:
        with open(yamlpath, "r") as stream:
            try:
                yaml.safe_load(stream)
                print(f"Validated YAML in {yamlpath}")
            except yaml.YAMLError:
                print(f"Failed to validate YAML in {yamlpath}")
                raise

    # Run server and exit when it does
    os.environ["PYGEOAPI_CONFIG"] = geoapi_config_name
    os.environ["PYGEOAPI_OPENAPI"] = openapi_config_name
    sys.exit(cli(["serve"]))
