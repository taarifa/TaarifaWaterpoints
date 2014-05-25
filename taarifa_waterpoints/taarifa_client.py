"""
Very, VERY basic python client lib for Taarifa

by the way, this is not how we'd want an actual client lib to be...
should be built on the requests lib, or standard lib stuff if we don't use any
sort of authentication. However, for now, this is fast to use taarifa_api + eve
for posts.
"""

from taarifa_api import add_document


def create_request(wp, status, first_name=None, last_name=None, email=None):
  """Create an example request reporting a broken waterpoint"""
  r = {'service_code': 'wps001',
         'attribute': {
           'waterpoint_id': wp,
           'status': status
          },
       'first_name': first_name,
       'last_name': last_name,
       'email': email
      }
  response = add_document('requests', r)
  return response
