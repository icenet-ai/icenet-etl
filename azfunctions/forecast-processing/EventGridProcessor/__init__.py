import json
import logging
import os
import time

from azure.communication.email import EmailClient
import azure.functions as func

def main(event: func.EventGridEvent):
    result = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    })

    logging.info("IceNet EventGrid trigger processed an event: {}".format(result))

    # Upload and consume configuration for rule processing based on it
    # https://github.com/Azure-Samples/communication-services-python-quickstarts/blob/main/send-email/send-email.py

    message = """IceNet Forecast: please review latest forecast...

{}
{}""".format(event.subject, result)

    # Staging email
    try:
        from_addr = os.environ["COMMS_FROM_EMAIL"]
        to_addr = os.environ["COMMS_TO_EMAIL"]
    except KeyError as e:
        logging.exception("Missing keys for communications, please set COMMS_FROM_EMAIL and COMMS_TO_EMAIL")
    send_email(from_addr, to_addr, event.subject, message)

def send_email(from_addr, to_addr, subject, message, poller_wait=10):
    try:
        connection_string = os.environ["COMMS_ENDPOINT"]
        client = EmailClient.from_connection_string(connection_string)

        content = {
            "subject": "Forecast arrived with IceNet Event Processor",
            "plainText": message,
            "html": "<html><p>{}</p></html>".format(message),
        }

        recipients = {"to": [{"address": to_addr}]}

        message = {
            "senderAddress":    from_addr,
            "content":          content,
            "recipients":       recipients,
        }

        poller = client.begin_send(message)

        time_elapsed = 0

        while not poller.done():
            logging.info("Email send poller status: " + poller.status())

            poller.wait(poller_wait)
            time_elapsed += poller_wait

            if time_elapsed > 18 * poller_wait:
                raise RuntimeError("Polling timed out.")

        if poller.result()["status"] == "Succeeded":
            logging.info(f"Successfully sent the email (operation id: {poller.result()['id']})")
        else:
            raise RuntimeError(str(poller.result()["error"]))

    except Exception as ex:
        logging.exception(ex)

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Usage: {} from_addr to_addr".format(sys.argv[0]))
        sys.exit(1)

    message = "TEST: {}".format("no_file.nc")
    from_addr = sys.argv[1]
    to_addr = sys.argv[2]
    send_email(from_addr, to_addr, "no_file.nc", message)
