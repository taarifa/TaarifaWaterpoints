from flask.ext.script import Manager

from taarifa_api import add_document
from taarifa_waterpoints import app
from taarifa_waterpoints.schemas import facility_schema

manager = Manager(app)


def check(response):
    data, _, _, status_code = response
    print "Succeeded" if status_code == 201 else "Failed", "with", status_code
    print data


@manager.command
def create_waterpoints():
    """Create facility for waterpoints."""
    check(add_document('facilities', facility_schema))

if __name__ == "__main__":
    manager.run()
