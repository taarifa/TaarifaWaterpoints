#! /usr/bin/env python

from os import environ
from subprocess import check_call
from urlparse import urlparse

if 'MONGOLAB_URI' in environ:
    print 'Using', environ['MONGOLAB_URI']
    url = urlparse(environ['MONGOLAB_URI'])
    cmd = 'mongo -u %s -p %s %s:%d/%s' % (url.username,
                                          url.password,
                                          url.hostname,
                                          url.port,
                                          url.path[1:])
else:
    cmd = 'mongo TaarifaAPI'
check_call(cmd, shell=True)
