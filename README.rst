Taarifa Waterpoints
===================

Background
__________

Taarifa_ is an open source platform for the crowd sourced reporting and
triaging of infrastructure related issues. Think of it as a bug tracker
for the real world which helps to engage citizens with their local
government.

The Taarifa platform is built around the `Taarifa API`_, a RESTful
service offering that clients can interact with to create and triage
'bugreports' relating to public infrastructure (e.g., the public toilet
is broken).


Waterpoints
___________

This repository contains an example application around Waterpoint
Management built on top of the core API.  It contains scripts to import
Waterpoint data (resources) which then become available through the API
to file requests against (e.g., waterpoint 2345 is broken and needs
fixing).

There is also an angularjs_ web application that illustrates how a user
can interact with the API and data through a browser.


Installation
____________

Requires Python, pip & the `Taarifa API`_ to be installed and MongoDB to
be running.

Clone the repository ::

  git clone https://github.com/taarifa/TaarifaWaterpoints

Install the requirements ::

  pip install -r requirements.txt

We suggest you use virtualenv_ for managing your python environment.

Ensure you have node.js and npm installed. Then, from the
`TaarifaWaterpoints` directory, install the dependencies: ::

  npm install


Usage
_____

From the TaarifaWaterpoints directory run the following command to
create the waterpoint schemas: ::

  python manage.py create_waterpoints

Then upload the waterpoint data: ::

  python manage.py upload_waterpoints <path-to-waterpoints-csv.gz>

Start the application from the TaarifaWaterpoints directory by running: ::

  python manage.py runserver

To check things are working, open a browser and navigate to: ::

  http://localhost:5000/api/waterpoints

This should show a list of all the waterpoint resources currently in the
database.

To use the web application simply start the server using grunt: ::

  grunt serve --watch

Then navigate to: ::

  http://localhost:9000


Contribute
__________

There is still much left do do and Taarifa is currently undergoing rapid
development. To get started send a message to the taarifa-dev_
mailinglist and check out the github issues. We use the github pull
request model for all contributions. Refer to the `contributing
guidelines`_ for further details.

.. _Taarifa: http://taarifa.org
.. _taarifa-dev: https://groups.google.com/forum/#!forum/taarifa-dev
.. _Taarifa API: http://github.com/taarifa/TaarifaAPI
.. _angularjs: https://angularjs.org/
.. _virtualenv: http://virtualenv.org
.. _contributing guidelines: CONTRIBUTING.rst
