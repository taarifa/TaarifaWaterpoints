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


Prerequisites
_____________

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
Windows can be used as the platform to run Taarifa - the main caveat here however is that as you install the dependencies, these are not added to the $PATH variable - this either needs to be added manually  

TaarifaWaterpoints installation instructions on windows - details for these steps are the same as for MacOS/Linux (except for apt-get lines): 

1) install python
2) install pip
3) install [nodejs]() and npm (these need to be added to the $PATH variable!)
3) install and run mongodb (does not automagically come with a service, so it needs to be started manually: )

  "c:\Program Files\MongoDB 2.6 Standard\bin\mongod.exe" --dbpath c:\temp\taarifa\

4) create the needed services and facilities
5) import the waterpoints in the same way as in the Mac OS/Linux instructions following:

  <path_to_python>\python.exe <path_to_TaarifaWaterpoints_Directory>\manage.py upload_waterpoints <waterpoints_csv.gz_file>



Installation
____________

.. note::
  The following steps are part of the `bootstrap.sh` script, so you may choose
  to execute that instead.

Requires Python, pip and the `Taarifa API`_ to be installed and MongoDB to
be running.

To ease development and debugging we suggest you use virtualenv_. 
Install virtualenv_ and virtualenvwrapper (you might need `sudo` for this): ::

  pip install virtualenv virtualenvwrapper

`Set up virtualenvwrapper`_ according to your shell and create a virtualenv: ::

  mkvirtualenv TaarifaAPI

If you already created the virtualenv for the `Taarifa API`_, activate it: ::

  workon TaarifaAPI

Clone the repository ::

  git clone https://github.com/taarifa/TaarifaWaterpoints

Change into directory and install the requirements ::
  
  cd TaarifaWaterpoints
  pip install -r requirements.txt

Ensure you have node.js and npm installed. Then, from the
`TaarifaWaterpoints` directory, install the dependencies: ::

  npm install

Install the Grunt_ command line interface (may require `sudo`): ::

  npm install -g grunt-cli

Continue with the usage section.

Installation using a virtual machine
____________________________________

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
_____

Make sure the virtualenv is active: ::

  workon TaarifaAPI

From the TaarifaWaterpoints directory run the following commands to
create the waterpoint schemas: ::

  python manage.py create_facility
  python manage.py create_service
  
Then upload the waterpoint data: ::

  python manage.py upload_waterpoints <path-to-waterpoints-csv.gz>

Start the application from the TaarifaWaterpoints directory by running: ::

  python manage.py runserver -r -d

By default the API server is only accessible from the local machine. If access
from the outside is required (e.g. when running from inside a VM), run: ::

  python manage.py runserver -h 0.0.0.0 -r -d

The flags ``-r`` and ``-d`` cause the server to run in debug mode and reload
automatically when files are changed.

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
.. _Python: http://python.org
.. _pip: https://pip.pypa.io/en/latest/installing.html
.. _nodejs: http://nodejs.org
.. _npm: http://npmjs.org
.. _MongoDB: http://mongodb.org
.. _virtualenv: http://virtualenv.org
.. _Set up virtualenvwrapper: http://virtualenvwrapper.readthedocs.org/en/latest/install.html#shell-startup-file
.. _Grunt: http://gruntjs.com
.. _Vagrant: http://vagrantup.com
.. _Vagrantfile: Vagrantfile
.. _VirtualBox: https://www.virtualbox.org
.. _contributing guidelines: CONTRIBUTING.rst
