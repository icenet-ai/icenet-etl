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
    from_addr = "DoNotReply@7ded58ea-c7b3-4bdc-9205-7d2e6a4fbe9e.azurecomm.net"
    to_addr = os.environ["DESTINATION_EMAIL"] \
        if "DESTINATION_EMAIL" in os.environ else "jambyr@bas.ac.uk"
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
    message = "TEST: {}".format("no_file.nc")
    from_addr = "DoNotReply@f246be03-b956-4ce0-af11-bda87251aa8c.azurecomm.net"
    to_addr = "jambyr@bas.ac.uk"
    send_email(from_addr, to_addr, "no_file.nc", message)
