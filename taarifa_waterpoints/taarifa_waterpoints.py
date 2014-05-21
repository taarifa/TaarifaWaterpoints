from flask import make_response, send_from_directory
import json

from taarifa_api import api as app, main

app.name = 'TaarifaWaterpoints'


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/stats')
def waterpoint_stats():
    "Return number of waterpoints of a given status in a given district."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    return make_response(json.dumps(app.data.driver.db['resources'].group(
        ['district', 'status'], {}, initial={'count': 0},
        reduce="function(curr, result) {result.count++;}")))


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


@app.route("/")
def index():
    return send_from_directory(app.root_path + '/dist/', 'index.html')


@app.route("/favicon.ico")
def favicon():
    return send_from_directory(app.root_path + '/dist/', 'favicon.ico')

if __name__ == '__main__':
    main()
