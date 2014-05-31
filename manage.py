from csv import DictReader
from datetime import datetime
import gzip
from pprint import pprint

from flask.ext.script import Manager

from taarifa_api import add_document, delete_documents, get_schema
from taarifa_waterpoints import app
from taarifa_waterpoints.schemas import facility_schema, service_schema

manager = Manager(app)


def check(response, success=201):
    data, _, _, status = response
    print "Succeeded" if status == success else "Failed", "with", status
    print "Response:"
    pprint(data)


@manager.option("resource", help="Resource to show the schema for")
def show_schema(resource):
    """Show the schema for a given resource."""
    pprint(get_schema(resource))


@manager.command
def list_routes():
    """List all routes defined for the application."""
    import urllib
    for rule in sorted(app.url_map.iter_rules(), key=lambda r: r.endpoint):
        methods = ','.join(rule.methods)
        print urllib.unquote("{:40s} {:40s} {}".format(rule.endpoint, methods,
                                                       rule))


@manager.command
def create_facility():
    """Create facility for waterpoints."""
    check(add_document('facilities', facility_schema))


@manager.command
def create_service():
    """Create service for waterpoints."""
    check(add_document('services', service_schema))


@manager.command
def delete_facilities():
    """Delete all facilities."""
    check(delete_documents('facilities'), 200)


@manager.command
def delete_services():
    """Delete all services."""
    check(delete_documents('services'), 200)


@manager.option("filename", help="gzipped CSV file to upload (required)")
@manager.option("--skip", type=int, default=0, help="Skip a number of records")
@manager.option("--limit", type=int, help="Only upload a number of records")
def upload_waterpoints(filename, skip=0, limit=None):
    """Upload waterpoints from a gzipped CSV file."""
    convert = {
        'date_recorded': lambda s: datetime.strptime(s, '%m/%d/%Y'),
        'population': int,
        'construction_year': lambda s: datetime.strptime(s, '%Y'),
        'breakdown_year': lambda s: datetime.strptime(s, '%Y'),
        'amount_tsh': float,
        'gps_height': float,
        'latitude': float,
        'longitude': float,
    }
    with gzip.open(filename) as f:
        reader = DictReader(f)
        for i in range(skip):
            reader.next()
        for i, d in enumerate(reader):
            d = dict((k, convert.get(k, str)(v)) for k, v in d.items() if v)
            d['facility_code'] = 'wpf001'
            check(add_document('waterpoints', d))
            if limit and i >= limit:
                break


@manager.option("status", help="Status (functional or non functional)")
@manager.option("wp", help="Waterpoint id")
def create_request(wp, status):
    """Create an example request reporting a broken waterpoint"""
    r = {"service_code": "wps001",
         "attribute": {"waterpoint_id": wp,
                       "status": status}}
    check(add_document("requests", r))


@manager.command
def delete_waterpoints():
    """Delete all existing waterpoints."""
    print delete_documents('waterpoints')

if __name__ == "__main__":
    manager.run()
