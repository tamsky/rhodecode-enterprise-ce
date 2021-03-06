.. _debug-mode:

Enabling Debug Mode
-------------------

Debug Mode will enable debug logging, and request tracking middleware. Debug Mode
enabled DEBUG log-level which allows tracking various information about authentication
failures, LDAP connection, email etc.

The request tracking will add a special
unique ID: `| req_id:00000000-0000-0000-0000-000000000000` at the end of each log line.
The req_id is the same for each individual requests, it means that if you want to
track particular user logs only, and exclude other concurrent ones
simply grep by `req_id` uuid which you'll have to find for the individual request.

To enable debug mode on a |RCE| instance you need to set the debug property
in the :file:`/home/{user}/.rccontrol/{instance-id}/rhodecode.ini` file. To
do this, use the following steps

1. Open the file and set the ``debug`` line to ``true``
2. Restart you instance using the ``rccontrol restart`` command,
   see the following example:

.. code-block:: ini

    [DEFAULT]
    debug = true

.. code-block:: bash

    # Restart your instance
    $ rccontrol restart enterprise-1
    Instance "enterprise-1" successfully stopped.
    Instance "enterprise-1" successfully started.


Debug and Logging Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Further debugging and logging settings can also be set in the
:file:`/home/{user}/.rccontrol/{instance-id}/rhodecode.ini` file.

In the logging section, the various packages that run with |RCE| can have
different debug levels set. If you want to increase the logging level change
``level = DEBUG`` line to one of the valid options.

You also need to change the log level for handlers. See the example
``##handler`` section below. The ``handler`` level takes the same options as
the ``debug`` level.

.. code-block:: ini

    ################################
    ### LOGGING CONFIGURATION   ####
    ################################
    [loggers]
    keys = root, sqlalchemy, beaker, celery, rhodecode, ssh_wrapper

    [handlers]
    keys = console, console_sql, file, file_rotating

    [formatters]
    keys = generic, color_formatter, color_formatter_sql

    #############
    ## LOGGERS ##
    #############
    [logger_root]
    level = NOTSET
    handlers = console

    [logger_sqlalchemy]
    level = INFO
    handlers = console_sql
    qualname = sqlalchemy.engine
    propagate = 0

    [logger_beaker]
    level = DEBUG
    handlers =
    qualname = beaker.container
    propagate = 1

    [logger_rhodecode]
    level = DEBUG
    handlers =
    qualname = rhodecode
    propagate = 1

    [logger_ssh_wrapper]
    level = DEBUG
    handlers =
    qualname = ssh_wrapper
    propagate = 1

    [logger_celery]
    level = DEBUG
    handlers =
    qualname = celery

    ##############
    ## HANDLERS ##
    ##############

    [handler_console]
    class = StreamHandler
    args = (sys.stderr, )
    level = DEBUG
    formatter = generic

    [handler_console_sql]
    class = StreamHandler
    args = (sys.stderr, )
    level = INFO
    formatter = generic

    [handler_file]
    class = FileHandler
    args = ('rhodecode_debug.log', 'a',)
    level = INFO
    formatter = generic

    [handler_file_rotating]
    class = logging.handlers.TimedRotatingFileHandler
    # 'D', 5 - rotate every 5days
    # you can set 'h', 'midnight'
    args = ('rhodecode_debug_rotated.log', 'D', 5, 10,)
    level = INFO
    formatter = generic

    ################
    ## FORMATTERS ##
    ################

    [formatter_generic]
    class = rhodecode.lib.logging_formatter.ExceptionAwareFormatter
    format = %(asctime)s.%(msecs)03d [%(process)d] %(levelname)-5.5s [%(name)s] %(message)s
    datefmt = %Y-%m-%d %H:%M:%S

    [formatter_color_formatter]
    class = rhodecode.lib.logging_formatter.ColorFormatter
    format = %(asctime)s.%(msecs)03d [%(process)d] %(levelname)-5.5s [%(name)s] %(message)s
    datefmt = %Y-%m-%d %H:%M:%S

    [formatter_color_formatter_sql]
    class = rhodecode.lib.logging_formatter.ColorFormatterSql
    format = %(asctime)s.%(msecs)03d [%(process)d] %(levelname)-5.5s [%(name)s] %(message)s
    datefmt = %Y-%m-%d %H:%M:%S