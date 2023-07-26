# Standard library
import logging
import os
import time

# Third party
import azure.functions as func
from azure.eventgrid import EventGridPublisherClient, EventGridEvent
from azure.core.credentials import AzureKeyCredential

# Local
from .processor import Processor
from .utils import human_readable, InputBlobTriggerException


def main(inputBlob: func.InputStream):
    time_start = time.monotonic()
    log_prefix = f"[{os.path.splitext(os.path.basename(inputBlob.name))[0]}]"
    logging.info(
        f"{log_prefix} Processing Azure blob: {inputBlob.name} ({inputBlob.length} bytes)"
    )
    processor = Processor(log_prefix, 100000)
    try:
        processor.load(inputBlob)
        processor.update_geometries()
        processor.update_forecasts()
        processor.update_latest_forecast()
        processor.update_forecast_meta()
    except InputBlobTriggerException as exc:
        logging.error(f"{log_prefix} Failed with message:\n{exc}")
    logging.info(f"{log_prefix} Finished processing Azure blob: {inputBlob.name}")
    logging.info(
        f"{log_prefix} Total time: {human_readable(time.monotonic() - time_start)}"
    )

    if "EVENTGRID_DOMAIN_KEY" in os.environ:
        domain_key = os.environ["EVENTGRID_DOMAIN_KEY"]
        domain_hostname = os.environ["EVENTGRID_DOMAIN_ENDPOINT"]
        domain_topic = os.environ["EVENTGRID_DOMAIN_TOPIC"]

        try:
            logging.info(f"Key supplied for event grid publishing, connecting to {domain_hostname}")
            credential = AzureKeyCredential(domain_key)
            client = EventGridPublisherClient(domain_hostname, credential)

            logging.info(f"Publishing icenet.forecast.processed event to {domain_topic}")
            client.send([
                EventGridEvent(
                    topic=domain_topic,
                    event_type="icenet.forecast.processed",
                    data={
                        "filename": f"{inputBlob.name}"
                    },
                    subject=f"{os.path.splitext(os.path.basename(inputBlob.name))[0]} has been processed into DB",
                    data_version="2.0"
                )
            ])
            logging.info(f"Event published")
        except Exception as ex:
            logging.exception(ex)
