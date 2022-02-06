# Standard library
import logging

# Third party
import azure.functions as func

# Local
from .processor import Processor


def main(inputBlob: func.InputStream):
    logging.info(f"Processing Azure blob: {inputBlob.name} ({inputBlob.length} bytes)")
    processor = Processor(50000)
    processor.load(inputBlob)
    processor.update_geometries()
    processor.update_forecasts()
    processor.update_latest_forecast()
    logging.info(f"Finished processing Azure blob: {inputBlob.name}")
