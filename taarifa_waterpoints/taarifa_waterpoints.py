import json
import mimetypes
from eve.render import send_response
from flask import request, send_from_directory
from werkzeug.contrib.cache import SimpleCache
cache = SimpleCache()

from taarifa_api import api as app, main


def pre_get_waterpoints(request, lookup):
    """
    Generate spatial query against waterpoint location from lat, lon,
    minDistance and maxDistance request arguments. The default value
    of maxDistance is 500m.
    """
    lat = request.args.get('lat', None, type=float)
    lon = request.args.get('lon', None, type=float)
    max_distance = request.args.get('maxDistance', 500, type=int)
    min_distance = request.args.get('minDistance', None, type=int)

    if lat and lon:
        lat = lat if -90 <= lat <= 90 else None
        lon = lon if -180 <= lon <= 180 else None
    if max_distance:
        max_distance = max_distance if max_distance >= 0 else None
    if min_distance:
        min_distance = min_distance if min_distance >= 0 else None

    if lat and lon:
        lookup['location'] = {
            '$near': {
                "$geometry": {
                    "type": "Point",
                    "coordinates": [lat, lon]
                },
            }
        }
        if max_distance:
            lookup['location']['$near']['$maxDistance'] = max_distance
        if min_distance:
            lookup['location']['$near']['$minDistance'] = min_distance


def post_waterpoints_get_callback(request, payload):
    """Strip all meta data but id from waterpoint payload if 'strip' is set to
    a non-zero value in the query string."""
    if request.args.get('strip', 0):
        try:
            d = json.loads(payload.data)
            d['_items'] = [dict((k, v) for k, v in it.items()
                                if k == '_id' or not k.startswith('_'))
                           for it in d['_items']]
            payload.data = json.dumps(d)
        except (KeyError, ValueError):
            # If JSON decoding fails or the object has no key _items
            pass

app.name = 'TaarifaWaterpoints'
app.on_post_GET_waterpoints += post_waterpoints_get_callback
app.on_pre_GET_waterpoints += pre_get_waterpoints

# Override the maximum number of results on a single page
# This is needed by the dashboard
# FIXME: this should eventually be replaced by an incremental load
# which is better for responsiveness
app.config['PAGINATION_LIMIT'] = 70000


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/requests')
def waterpoint_requests():
    "Return the unique values for a given field in the waterpoints collection."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    reqs = app.data.driver.db['requests'].find(
        {'status': 'open'},
        ['attribute.waterpoint_id'])
    return send_response('requests', (reqs.distinct('attribute.waterpoint_id'),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/values/<field>')
def waterpoint_values(field):
    "Return the unique values for a given field in the waterpoints collection."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    if request.args:
        resources = resources.find(dict(request.args.items()))
    return send_response('resources', (sorted(resources.distinct(field)),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/stats')
def waterpoint_stats():
    "Return number of waterpoints grouped by district and status."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.group(
        ['district', 'status_group'], dict(request.args.items()),
        initial={'count': 0},
        reduce="function(curr, result) {result.count++;}"),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/status')
def waterpoint_status():
    "Return number of waterpoints grouped by status."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.group(
        ['status_group'], dict(request.args.items()), initial={'count': 0},
        reduce="function(curr, result) {result.count++;}"),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/count_by/<field>')
def waterpoint_count_by(field):
    "Return number of waterpoints grouped a given field."
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.group(
        field.split(','), dict(request.args.items()), initial={'count': 0},
        reduce="function(curr, result) {result.count++;}"),))


@app.route('/' + app.config['URL_PREFIX'] + '/waterpoints/stats_by/<field>')
def waterpoint_stats_by(field):
    """Return number of waterpoints of a given status grouped by a certain
    attribute."""
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.aggregate([
        {"$match": dict(request.args.items())},
        {"$group": {"_id": {field: "$" + field,
                            "status": "$status_group"},
                    "statusCount": {"$sum": 1},
                    "populationCount": {"$sum": "$pop_served"}}},
        {"$group": {"_id": "$_id." + field,
                    "waterpoints": {
                        "$push": {
                            "status": "$_id.status",
                            "count": "$statusCount",
                            "population": "$populationCount",
                        },
                    },
                    "count": {"$sum": "$statusCount"}}},
        {"$project": {"_id": 0,
                      field: "$_id",
                      "waterpoints": 1,
                      "population": 1,
                      "count": 1}},
        {"$sort": {field: 1}}])['result'],))


@app.route('/scripts/<path:filename>')
def scripts(filename):
    return send_from_directory(app.root_path + '/dist/scripts/', filename)


@app.route('/styles/<path:filename>')
def styles(filename):
    return send_from_directory(app.root_path + '/dist/styles/', filename)


@app.route('/images/<path:filename>')
def images(filename):
    return send_from_directory(app.root_path + '/dist/images/', filename)


@app.route('/data/<path:filename>.topojson')
def topojson(filename):
    return send_from_directory(app.root_path + '/dist/data/', filename + '.topojson',
                               mimetype='application/json')


@app.route('/data/<path:filename>')
def data(filename):
    mimetype, _ = mimetypes.guess_type(filename)
    return send_from_directory(app.root_path + '/dist/data/', filename, mimetype=mimetype)


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
