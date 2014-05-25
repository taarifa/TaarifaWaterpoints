
from flask import request, send_from_directory
import json

from taarifa_api import api as app, main
import taarifa_email

app.name = 'TaarifaWaterpoints'


@app.route('/scripts/<path:filename>')
def scripts(filename):
    return send_from_directory(app.root_path + '/dist/scripts/', filename)


@app.route('/styles/<path:filename>')
def styles(filename):
    return send_from_directory(app.root_path + '/dist/styles/', filename)


@app.route('/images/<path:filename>')
def images(filename):
    return send_from_directory(app.root_path + '/dist/images/', filename)


@app.route('/views/<path:filename>')
def views(filename):
    return send_from_directory(app.root_path + '/dist/views/', filename)


@app.route('/')
def index():
    return send_from_directory(app.root_path + '/dist/', 'index.html')


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(app.root_path + '/dist/', 'favicon.ico')


@app.route('/email', methods=['POST'])
def email():
  parsed_data = taarifa_email.parse_email_webhook(request.data)
  app.logger.info('parsed_data: %s' % json.dumps(parsed_data, indent=2))
  return 'True'


if __name__ == '__main__':
    main()
