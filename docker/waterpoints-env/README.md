# Taarifa Waterpoints development environment image

This image provides a development environment for running Taarifa Waterpoints.

The container exposes the following ports:
* 5000 for the Flask web server
* 9000 for the Grunt development server
* 27017 for MongoDB

Launch the container and map the ports to the corresponding ones on the host:

    docker run -p 5000:5000 -p 27017:27017 -t -i taarifa/waterpoints-env:latest

To install Taarifa Waterpoints inside the container you can run the script:

    ./update_taarifa.sh

Alternatively you can map your local development environment from the host into
the container (note that you still need to install the dependencies):

    docker run -p 5000:5000 -p 27017:27017 \
      -v /path/to/TaarifaAPI:/home/taarifa/TaarifaAPI \
      -v /path/to/TaarifaWaterpoints:/home/taarifa/TaarifaWaterpoints \
      -t -i taarifa/waterpoints-env:latest

From inside the container, start the Flask server listening on any IP address:

    cd TaarifaWaterpoints
    python manage.py runserver -h 0.0.0.0
