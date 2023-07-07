import json
import logging
import os
import time

from azure.communication.email import EmailClient, EmailContent, EmailAddress, EmailMessage, EmailRecipients
import azure.functions as func

def main(event: func.EventGridEvent):
    result = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    })

    logging.info('IceNet EventGrid trigger processed an event: %s', event.subject)

    # Upload and consume configuration for rule processing based on it
    # https://github.com/Azure-Samples/communication-services-python-quickstarts/blob/main/send-email/send-email.py

    message = """IceNet Forecast: {} has SIC threshold changes that are of concern,
              please review latest forecast...""".format(event.subject)

    # Staging email
    try:
        from_addr = os.environ["COMMS_FROM_EMAIL"]
        to_addr = os.environ["COMMS_TO_EMAIL"]
    except KeyError as e:
        logging.exception("Missing keys for communications, please set COMMS_FROM_EMAIL and COMMS_TO_EMAIL")
    send_email(from_addr, to_addr, event.subject, message)

def send_email(from_addr, to_addr, subject, message):
    try:
        connection_string = os.environ["COMMS_ENDPOINT"]
        client = EmailClient.from_connection_string(connection_string)
        content = EmailContent(
            subject="Forecast arrived with IceNet Event Processor",
            plain_text=message,
            html= "<html><p>{}</p></html>".format(message),
        )

        recipient = EmailAddress(email=to_addr, display_name=to_addr)

        message = EmailMessage(
            sender=from_addr,
            content=content,
            recipients=EmailRecipients(to=[recipient])
        )

        response = client.send(message)
        if (not response or response.message_id=='undefined' or response.message_id==''):
            logging.info("Message Id not found.")
        else:
            logging.info("Send email succeeded for message_id :"+ response.message_id)
            message_id = response.message_id
            counter = 0
            while True:
                counter+=1
                send_status = client.get_send_status(message_id)

                if (send_status):
                    logging.info(f"Email status for message_id {message_id} is {send_status.status}.")
                if (send_status.status.lower() == "queued" and counter < 12):
                    time.sleep(10)  # wait for 10 seconds before checking next time.
                    counter +=1
                else:
                    if(send_status.status.lower() == "outfordelivery"):
                        logging.info(f"Email delivered for message_id {message_id}.")
                        break
                    else:
                        logging.info("Looks like we timed out for checking email send status.")
                        break

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
