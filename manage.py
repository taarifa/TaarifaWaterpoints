from csv import DictReader
from datetime import datetime
import gzip
from pprint import pprint

from flask.ext.script import Manager

from taarifa_api import add_document, delete_documents, get_schema
from taarifa_waterpoints import app
from taarifa_waterpoints.schemas import facility_schema, service_schema

manager = Manager(app)


def check(response):
    data, _, _, status_code = response
    print "Succeeded" if status_code == 201 else "Failed", "with", status_code
    print data


@manager.option("resource", help="Resource to show the schema for")
def show_schema(resource):
    """Show the schema for a given resource."""
    pprint(get_schema(resource))


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
    check(delete_documents('facilities'))


@manager.option("filename", help="gzipped CSV file to upload (required)")
def upload_waterpoints(filename):
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
        for d in DictReader(f):
            d = dict((k, convert.get(k, str)(v)) for k, v in d.items() if v)
            d['facility_code'] = 'wp001'
            check(add_document('waterpoints', d))


@manager.command
def delete_waterpoints():
    """Delete all existing waterpoints."""
    print delete_documents('waterpoints')

if __name__ == "__main__":
    manager.run()
