# Standard library
import json
import logging
import os
import sys

# Local
from InputBlobTrigger import main

logging.basicConfig(
    datefmt=r"%Y-%m-%d %H:%M:%S",
    format="{asctime:s} {levelname:<8s} {module:>10s}.{funcName:<25s} {message:s}",
    level=logging.INFO,
    style="{",
)


class FileSystemBlob:
    def __init__(self, filename):
        self.name = filename
        self.length = 0

    def read(self):
        return open(self.name, "rb").read()


if __name__ == "__main__":
    settings = json.load(open(os.path.join(sys.path[0], "local.settings.json"), "r"))
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        os.environ["PSQL_HOST"] = os.getenv(
            "PSQL_HOST", settings["Values"]["PSQL_HOST"]
        )
        os.environ["PSQL_DB"] = os.getenv("PSQL_DB", settings["Values"]["PSQL_DB"])
        os.environ["PSQL_USER"] = os.getenv(
            "PSQL_USER", settings["Values"]["PSQL_USER"]
        )
        os.environ["PSQL_PWD"] = os.getenv("PSQL_PWD", settings["Values"]["PSQL_PWD"])
        main(FileSystemBlob(filename))
