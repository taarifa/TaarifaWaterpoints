import json


def parse_email_webhook(webhook_data):
  data = json.loads(webhook_data)
  parsed_data = {
    'email':    data['message_data']['addresses']['from']['email'],
    'name':     data['message_data']['addresses']['from']['name'],
    'subject':  data['message_data']['subject'],
    'body':     data['message_data']['body'][0]['content']
  }
  return parsed_data


def determine_action(data):
  # look at subject and take appropriate action
  subject = data['subject']

  if subject == 'status':
    update_status_request(data)


def update_status_request(data):
  """Parses the email body and pulls out waterpoint id + status [up, down]
  email body format is:

  Subject: status
  Body:
  <waterpoint_id>
  <up/down>
  """
  # parse body
  parsed_body = data['body'].split()
  data['waterpoint_id'] = parsed_body[0]
  data['status'] = parsed_body[1]

  # translate json

  # def make call
  pass
