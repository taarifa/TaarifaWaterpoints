Taarifa Waterpoints
===================

.. contents:: Table of Contents
Background
Waterpoints
Prequisites
Linux
Windows
Installation
Installation using a virtual machine
Usage
Deployment to Heroku
Contribute




Background
==========

Taarifa_ is an open source platform for the crowd sourced reporting and
triaging of infrastructure related issues. Think of it as a bug tracker
for the real world which helps to engage citizens with their local
government.

The Taarifa platform is built around the `Taarifa API`_, a RESTful
service offering that clients can interact with to create and triage
'bugreports' relating to public infrastructure (e.g., the public toilet
is broken).

For information on how to get inovoled, scroll to the Contributing section
at the bottom of the page.

Waterpoints
===========

This repository contains an example application around Waterpoint
Management built on top of the core API.  It contains scripts to import
Waterpoint data (resources) which then become available through the API
to file requests against (e.g., waterpoint 2345 is broken and needs
fixing).

There is also an angularjs_ web application that illustrates how a user
can interact with the API and data through a browser.


Prerequisites
=============

.. note::
  You may choose to install into a virtual machine as described further down.

Taarifa requires Python_, pip_, nodejs_, npm_ and MongoDB_ to be available on
the system.

.. note::
  pip_ >= 1.5 is required. if you have an older version you can upgrade (may
  require ``sudo``) with ::

    pip install -U pip

Linux
-----

If you are running Ubuntu you can simply execute the `install.sh` script ::

  ./install.sh

Some of the commands are executed with sudo and require sudo permission for the
currently logged in user.

On other distributions, use the package manager to install the packages
corresponding to those listed in `install.sh`.


Windows
-------

Windows can be used as the platform to run Taarifa - the main caveat here
however is that as you install the dependencies, these are not added to the
`$PATH` variable - this needs to be added manually.

Details for the following steps are the same as for MacOS/Linux (except for
the actual package installation): 

1.  Install Python_.
2.  Install pip_.
3.  Install nodejs_ and npm_ (these need to be added to the $PATH variable!)
4.  Install and run MongoDB_, which does not automagically come with a service,
    so it needs to be started manually. Open a command prompt and run: ::

    "c:\Program Files\MongoDB 2.6 Standard\bin\mongod.exe" --dbpath c:\mongo_databases\taarifa\


Installation
============

.. note::
  The following steps are part of the `bootstrap.sh` script, so you may choose
  to execute that instead.

Requires Python, pip and the `Taarifa API`_ to be installed and MongoDB to
be running.

To ease development and debugging we suggest you use virtualenv_. 
Install virtualenv_ and virtualenvwrapper (you might need admin rights for this): ::

  pip install virtualenv virtualenvwrapper
  
For windows only, install virtualenvwrapper-win_ using pip: ::

  pip install virtualenvwrapper-win

`Set up virtualenvwrapper`_ according to your shell and create a virtualenv: ::

  mkvirtualenv TaarifaAPI

If you already created the virtualenv for the `Taarifa API`_, activate it: ::

  workon TaarifaAPI

Clone the repository ::

  git clone https://github.com/taarifa/TaarifaWaterpoints

Change into directory and install the requirements ::
  
  cd TaarifaWaterpoints
  pip install -r requirements/dev.txt

Ensure you have node.js and npm installed. Then, from the
``TaarifaWaterpoints`` directory, install the npm dependencies: ::

  npm install

Install the Grunt_ and Bower_ command line interface (may require Adminstrator
permission): ::

  npm install -g grunt-cli
  npm install -g bower

Finally, install the frontend dependencies using Bower_: ::

  bower install

Continue with the usage section.

Installation using a virtual machine
-------------------------------------

Instead of following the installation instructions above you may choose to
set up a virtual machine with all dependencies installed. This process is fully
automated using Vagrant_ and the provided Vagrantfile_. Note that the
Vagrantfile is included in the repository and needs not be downloaded.

Install VirtualBox_ and Vagrant_ for your platform.

Clone the repositories into the same root folder. This is required since these
local folders are mounted in the VM such that you can edit files either on the
host or in the VM. ::

  git clone https://github.com/taarifa/TaarifaAPI
  git clone https://github.com/taarifa/TaarifaWaterpoints
  cd TaarifaWaterpoints

Start the VM. This may take quite a while the very first time as the VM image
needs to be downloaded (~360MB) and the VM provisioned with all dependencies.
On every subsequent use these steps are skipped. ::

  vagrant up

In case provisioning fails due to e.g. loss of network connection, run the
provisioning scripts again until successful: ::

  vagrant provision

Connect to the virtual machine and change into the `TaarifaWaterpoints`
folder: ::

  vagrant ssh
  cd TaarifaWaterpoints

You can then continue with the usage section below. The ports are automatically
forwarded so you can access the API and frontend from your host browser. Note
that both the `TaarifaAPI` and the `TaarifaWaterpoints` folders in the VM are
mounted from the host i.e. changes made on the host are immediately reflected in
the VM and vice versa. This allows you to work on the code either on the host or
in the VM according to your preference.

Usage
=====

.. note::
  When using a virtual machine, run the following commands in the VM.

Make sure the virtualenv is active: ::

  workon TaarifaAPI

From the TaarifaWaterpoints directory run the following commands to
create the waterpoint schemas: ::

  python manage.py create_facility
  python manage.py create_service
  
Then upload the `waterpoint data`_: ::

  python manage.py upload_waterpoints <path/to/waterpoints/file.csv>

Start the application from the TaarifaWaterpoints directory by running: ::

  python manage.py runserver -r -d

By default the API server is only accessible from the local machine. If access
from the outside is required (e.g. when running from inside a VM), run: ::

  python manage.py runserver -h 0.0.0.0 -r -d

The flags ``-r`` and ``-d`` cause the server to run in debug mode and reload
automatically when files are changed.

To verify things are working, open a browser (on the host when using the VM)
and navigate to: ::

  http://localhost:5000/api/waterpoints

This should show a list of all the waterpoint resources currently in the
database.

To work on the frontend web application start the `grunt` server (with the API
server running on port 5000) using: ::

  grunt serve --watch

Then navigate to (on the host when using the VM): ::

  http://localhost:9000

Grunt watches the `app` folder for changes and automatically reloads the
frontend in your browser as soon as you make changes.

To build the frontend (which is automatically done on deployment), use: ::

  grunt build

This creates a distribution in the `dist` folder, which is served via the
Flask development server running on port 5000. The build step needs to be run
again whenever the frontend in the `app` folder changes. Running `grunt serve`
is not required in this case.


Requirements
------------

Taarifa uses pip to install and manage python dependencies.

Conventionally this uses `requirements.txt`, but Heroku automatically installs
from there. Therefore a `requirements` folder is used as following:

    * Dev and deploy requirements in `requirements/base.txt`
    * Development *only* in `requirements/dev.txt`
    * Deployment *only* in `requirements/deploy.txt`


Deployment to Heroku
====================

To deploy to Heroku_, make sure the `Heroku tool belt`_ is installed. From the
TaarifaWaterpoints root folder, create a new app: ::

  heroku app:create <name>

This will add a new Git remote `heroku`, which is used to deploy the app. Run
`git remote -v` to check. To add the remote manually, do: ::

  git remote add heroku git@heroku.com:<name>.git

Since Taarifa uses Python for the API and Node.js to build the frontend, Heroku
build packs for both stacks are required. heroku-buildpack-multi_ enables the
use of multiple build packs, configured via the `.buildpacks` file. Before
deploying for the first time, the app needs to be configured to use it: ::

  heroku config:set BUILDPACK_URL=https://github.com/ddollar/heroku-buildpack-multi.git

Add the MongoLab Sandbox to provide the MongoDB database ::

  heroku addons:add mongolab

To be able to import the data into the MongoLab database, copy down the heroku
configuration to a `.env` file you can use with `foreman`: ::

  heroku config:pull

Make sure the virtualenv is active: ::

  workon TaarifaAPI

Create the waterpoint schemas and upload the `waterpoint data`_, which may take
several hours: ::

  foreman run python manage.py create_facility
  foreman run python manage.py create_service
  foreman run python manage.py upload_waterpoints <path/to/waterpoints/file.csv>

Alternatively, you can import a dump of your local database and import it. If
`mongod` is not running, create a dump directly from the database files in a
`dump` folder in your current directory: ::

  sudo -u mongodb mongodump --journal --db TaarifaAPI --dbpath /var/lib/mongodb

This assumes you have followed the `MongoDB installation instructions`_ on
Ubuntu. Otherwise you might not need to run the command as the `mongodb` user
and your database directory might be `/data/db`.

Import the dump into your MongoLab database, running the following command: ::

  mongorestore -h <host> -d <database> -u <user> -p <password> /path/to/dump/TaarifaAPI/

Extract host, database, user and password from the `MONGOLAB_URI` Heroku
configuration variable: ::

  heroku config:get MONGOLAB_URI

Once finished you are ready to deploy: ::

  git push heroku master

To set up a custom domain for the deployed app, register with heroku: ::

  heroku domains:add <domain>

and add a DNS record for it: ::

  <domain>.     10800   IN      CNAME   <appname>.herokuapp.com.

Contribute
==========

There is still much left do do and Taarifa is currently undergoing rapid
development. We aspire to be a very friendly and welcoming community to 
all skill levels.

To get started send a message to the taarifa-dev_ mailinglist introducing
yourself and your interest in Taarifa. With some luck you should also be
able to find somebody on our `IRC channel`_.

If you are comfortable you can also take a look at the github issues and
comment/fix to you heart's content.

We use the github pull request model for all contributions. Refer to the `contributing
guidelines`_ for further details.

.. _IRC channel: http://gwob.org/taarifa-irc
.. _Taarifa: http://taarifa.org
.. _taarifa-dev: https://groups.google.com/forum/#!forum/taarifa-dev
.. _Taarifa API: http://github.com/taarifa/TaarifaAPI
.. _angularjs: https://angularjs.org/
.. _Python: http://python.org
.. _pip: https://pip.pypa.io/en/latest/installing.html
.. _nodejs: http://nodejs.org
.. _npm: http://npmjs.org
.. _MongoDB: http://mongodb.org
.. _virtualenv: http://virtualenv.org
.. _Set up virtualenvwrapper: http://virtualenvwrapper.readthedocs.org/en/latest/install.html#shell-startup-file
.. _Grunt: http://gruntjs.com
.. _Bower: http://bower.io
.. _Vagrant: http://vagrantup.com
.. _Vagrantfile: Vagrantfile
.. _VirtualBox: https://www.virtualbox.org
.. _waterpoint data: https://drive.google.com/file/d/0B5dKo9igl8W4UmpHdjNGV09FZmM/view?usp=sharing
.. _Heroku: https://toolbelt.heroku.com
.. _Heroku tool belt: https://toolbelt.heroku.com
.. _heroku-buildpack-multi: https://github.com/ddollar/heroku-buildpack-multi
.. _MongoDB installation instructions: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/
.. _contributing guidelines: CONTRIBUTING.rst
.. _virtualenvwrapper-win: https://pypi.python.org/pypi/virtualenvwrapper-win
