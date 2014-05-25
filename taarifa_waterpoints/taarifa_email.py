import json

from taarifa_client import create_request


def handle_email_webhook(webhook_data):
  """Main function to handle an email webhook!"""
  parsed_webhook_data = parse_email_webhook(webhook_data)

  if parsed_webhook_data['subject'] == 'status':
    return create_status_request(parsed_webhook_data)


def parse_email_webhook(webhook_data):
  data = json.loads(webhook_data)
  parsed_data = {
    'email':    data['message_data']['addresses']['from']['email'].strip(),
    'name':     data['message_data']['addresses']['from']['name'].strip(),
    'subject':  data['message_data']['subject'].strip().lower(), # since this is like a command, to lower as well
    'body':     data['message_data']['body'][0]['content'].strip()
  }
  return parsed_data


def create_status_request(data):
  """Parses the email body and pulls out waterpoint id + status [up, down]
  email body format is:

  Subject: status
  Body:
  <waterpoint_id>
  <1/0> - 1 = functional, 0 = not functional

  Then creates a new request with that information
  """
  # parse body
  parsed_body = data['body'].split()
  names = data['name'].split()

  email = data['email']
  first_name = names[0]
  last_name = names[1]
  wp = parsed_body[0]

  # set proper status
  if parsed_body[1]:
    status = 'functional'
  else:
    status = 'not functional'

  params = {
    'email': email,
    'first_name': first_name,
    'last_name': last_name,
    'wp': wp,
    'status': status
  }

  # make call
  return create_request(**params)
