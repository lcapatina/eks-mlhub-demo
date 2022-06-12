[app:main]
use = egg:pypicloud

pyramid.reload_templates = False
pyramid.debug_authorization = false
pyramid.debug_notfound = false
pyramid.debug_routematch = false
pyramid.default_locale_name = en

pypi.default_read =
    everyone
pypi.default_write =
    authenticated

pypi.storage = s3
storage.aws_access_key_id = ${pypi_aws_access_key_id}
storage.aws_secret_access_key = ${pypi_aws_access_key_secret}
storage.bucket = ${pypi_bucket_name}


db.url = sqlite:////var/lib/pypicloud/db.sqlite

# For beaker
session.encrypt_key = none
session.validate_key = none
session.secure = False
session.invalidate_corrupt = true

###
# wsgi server configuration
###

[uwsgi]
paste = config:%p
paste-logger = %p
master = true
processes = 20
reload-mercy = 15
worker-reload-mercy = 15
max-requests = 1000
enable-threads = true
http = 0.0.0.0:8080
uid = pypicloud
gid = pypicloud

###
# logging configuration
# http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/logging.html
###

[loggers]
keys = root, botocore, pypicloud

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = INFO
handlers = console

[logger_pypicloud]
level = DEBUG
qualname = pypicloud
handlers =

[logger_botocore]
level = WARN
qualname = botocore
handlers =

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)s %(asctime)s [%(name)s] %(message)s
