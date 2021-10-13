# Standard library
import logging
# Third party
import azure.functions as func
# Local
from .processor import Processor

def main(inputBlob: func.InputStream):
    logging.info(f"Processing Azure blob: {inputBlob.name} ({inputBlob.length} bytes)")
    processor = Processor()
    processor.load(inputBlob)
    processor.update_geometries()
    processor.update_predictions()
    processor.update_latest_prediction()
    logging.info(f"Finished processing Azure blob: {inputBlob.name}")
