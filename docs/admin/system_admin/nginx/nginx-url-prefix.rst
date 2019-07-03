.. _nginx_url-pre:

Nginx URL Prefix Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Use the following example to configure Nginx to use a URL prefix.

.. code-block:: nginx

    location  /foo {
      rewrite /foo(.*) /$1  break;
      proxy_pass         http://localhost:3200;
      proxy_redirect     off;
      proxy_set_header   Host $host;
    }

In addition to the Nginx configuration you will need to add the following
lines (if they not exist) into the ``rhodecode.ini`` file.

* Above ``[app:main]`` section of the ``rhodecode.ini`` file add the
  following section if it doesn't exist yet.

.. code-block:: ini

    [filter:proxy-prefix]
    use = egg:PasteDeploy#prefix
    prefix = /<someprefix> # Change <someprefix> into your chosen prefix

* In the the ``[app:main]`` section of your ``rhodecode.ini`` file add the
  following line.

.. code-block:: ini

    filter-with = proxy-prefix


