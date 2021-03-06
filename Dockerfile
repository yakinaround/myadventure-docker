FROM ubuntu:14.04
MAINTAINER Martin Spier <spiermar@gmail.com>

# keep upstart quiet
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# no tty
ENV DEBIAN_FRONTEND noninteractive

# get up to date
RUN apt-get update --fix-missing

# global installs [applies to all envs!]
RUN apt-get install -y build-essential git
RUN apt-get install -y python python-dev python-setuptools
RUN apt-get install -y python-pip python-virtualenv
RUN apt-get install -y nginx supervisor
RUN apt-get install -y git
RUN apt-get install -y libxml2-dev libxslt1-dev python-dev
RUN apt-get install -y zlib1g-dev

# stop supervisor service as we'll run it manually
RUN service supervisor stop

# create a virtual environment and install all dependencies from pypi
RUN virtualenv /opt/venv
RUN /opt/venv/bin/pip install gunicorn
ADD ./myadventure-api/requirements.txt /opt/venv/requirements-api.txt
RUN /opt/venv/bin/pip install -r /opt/venv/requirements-api.txt
ADD ./myadventure-front/requirements.txt /opt/venv/requirements-front.txt
RUN /opt/venv/bin/pip install -r /opt/venv/requirements-front.txt

# expose port(s)
EXPOSE 80

RUN pip install supervisor-stdout

# file management, everything after an ADD is uncached, so we do it as late as
# possible in the process.
ADD ./supervisord.conf /etc/supervisord.conf
ADD ./nginx.conf /etc/nginx/nginx.conf

# restart nginx to load the config
RUN service nginx stop

# start supervisor to run our wsgi server
CMD supervisord -c /etc/supervisord.conf -n
