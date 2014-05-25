from eve.render import send_response
from flask import request, send_from_directory

from taarifa_api import api as app, main

app.name = 'TaarifaWaterpoints'


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/values/<field>')
def waterpoint_values(field):
    "Return the unique values for a given field in the waterpoints collection."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    if request.args:
        resources = resources.find(dict(request.args.items()))
    return send_response('resources', (resources.distinct(field),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/stats')
def waterpoint_stats():
    "Return number of waterpoints grouped by district and status."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.group(
        ['district', 'status'], dict(request.args.items()),
        initial={'count': 0},
        reduce="function(curr, result) {result.count++;}"),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/status')
def waterpoint_status():
    "Return number of waterpoints grouped by status."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.group(
        ['status'], dict(request.args.items()), initial={'count': 0},
        reduce="function(curr, result) {result.count++;}"),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/stats_by/<selector>')
def waterpoint_stats_by(selector):
    """Return number of waterpoints of a given status grouped by a certain
    attribute."""
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.aggregate([
        {"$match": dict(request.args.items())},
        {"$group": {"_id": {selector: "$" + selector,
                            "status": "$status"},
                    "statusCount": {"$sum": 1},
                    "populationCount": {"$sum": "$population"}}},
        {"$group": {"_id": "$_id." + selector,
                    "waterpoints": {
                        "$push": {
                            "status": "$_id.status",
                            "count": "$statusCount",
                            "population": "$populationCount",
                        },
                    },
                    "count": {"$sum": "$statusCount"}}},
        {"$project": {"_id": 0,
                      selector: "$_id",
                      "waterpoints": 1,
                      "population": 1,
                      "count": 1}}])['result'],))


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


@app.route("/dashboard")
def dashboard():
    return send_from_directory(app.root_path + '/dash/', 'index.html')


@app.route("/favicon.ico")
def favicon():
    return send_from_directory(app.root_path + '/dist/', 'favicon.ico')

if __name__ == '__main__':
    main()
