# Standard library
import logging
import sys

# Local
from InputBlobTrigger import main

logging.basicConfig(
    datefmt=r"%Y-%m-%d %H:%M:%S",
    format="{asctime:s} {levelname:<8s} {module:>10s}.{funcName:<20s} {message:s}",
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
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        main(FileSystemBlob(filename))
