.. _svn-http:

|svn| With Write Over HTTP
^^^^^^^^^^^^^^^^^^^^^^^^^^

To use |svn| with read/write support over the |svn| HTTP protocol, you have to
configure the HTTP |svn| backend.

Prerequisites
=============

- Enable HTTP support inside the admin VCS settings on your |RCE| instance
- You need to install the following tools on the machine that is running an
  instance of |RCE|:
  ``Apache HTTP Server`` and ``mod_dav_svn``.


Using Ubuntu 14.04 Distribution as an example execute the following:

.. code-block:: bash

    $ sudo apt-get install apache2 libapache2-mod-svn

Once installed you need to enable ``dav_svn``:

.. code-block:: bash

    $ sudo a2enmod dav_svn
    $ sudo a2enmod headers


Configuring Apache Setup
========================

.. tip::

   It is recommended to run Apache on a port other than 80, due to possible
   conflicts with other HTTP servers like nginx. To do this, set the
   ``Listen`` parameter in the ``/etc/apache2/ports.conf`` file, for example
   ``Listen 8090``.


.. warning::

   Make sure your Apache instance which runs the mod_dav_svn module is
   only accessible by |RCE|. Otherwise everyone is able to browse
   the repositories or run subversion operations (checkout/commit/etc.).

It is also recommended to run apache as the same user as |RCE|, otherwise
permission issues could occur. To do this edit the ``/etc/apache2/envvars``

   .. code-block:: apache

      export APACHE_RUN_USER=rhodecode
      export APACHE_RUN_GROUP=rhodecode

1. To configure Apache, create and edit a virtual hosts file, for example
   :file:`/etc/apache2/sites-available/default.conf`. Below is an example
   how to use one with auto-generated config ```mod_dav_svn.conf```
   from configured |RCE| instance.

.. code-block:: apache

    <VirtualHost *:8090>
        ServerAdmin rhodecode-admin@localhost
        DocumentRoot /var/www/html
        ErrorLog ${'${APACHE_LOG_DIR}'}/error.log
        CustomLog ${'${APACHE_LOG_DIR}'}/access.log combined
        Include /home/user/.rccontrol/enterprise-1/mod_dav_svn.conf
    </VirtualHost>


2. Go to the :menuselection:`Admin --> Settings --> VCS` page, and
   enable :guilabel:`Proxy Subversion HTTP requests`, and specify the
   :guilabel:`Subversion HTTP Server URL`.

3. Open the |RCE| configuration file,
   :file:`/home/{user}/.rccontrol/{instance-id}/rhodecode.ini`

4. Add the following configuration option in the ``[app:main]``
   section if you don't have it yet.

   This enables mapping of the created |RCE| repo groups into special
   |svn| paths. Each time a new repository group is created, the system will
   update the template file and create new mapping. Apache web server needs to
   be reloaded to pick up the changes on this file.
   To do this, simply configure `svn.proxy.reload_cmd` inside the .ini file.
   Example configuration:


.. code-block:: ini

    ############################################################
    ### Subversion proxy support (mod_dav_svn)               ###
    ### Maps RhodeCode repo groups into SVN paths for Apache ###
    ############################################################
    ## Enable or disable the config file generation.
    svn.proxy.generate_config = true
    ## Generate config file with `SVNListParentPath` set to `On`.
    svn.proxy.list_parent_path = true
    ## Set location and file name of generated config file.
    svn.proxy.config_file_path = %(here)s/mod_dav_svn.conf
    ## Used as a prefix to the <Location> block in the generated config file.
    ## In most cases it should be set to `/`.
    svn.proxy.location_root = /
    ## Command to reload the mod dav svn configuration on change.
    ## Example: `/etc/init.d/apache2 reload`
    svn.proxy.reload_cmd = /etc/init.d/apache2 reload
    ## If the timeout expires before the reload command finishes, the command will
    ## be killed. Setting it to zero means no timeout. Defaults to 10 seconds.
    #svn.proxy.reload_timeout = 10


This would create a special template file called ```mod_dav_svn.conf```. We
used that file path in the apache config above inside the Include statement.
It's also possible to generate the config from the
:menuselection:`Admin --> Settings --> VCS` page.


Using |svn|
===========

Once |svn| has been enabled on your instance, you can use it with the
following examples. For more |svn| information, see the `Subversion Red Book`_

.. code-block:: bash

    # To clone a repository
    svn checkout http://my-svn-server.example.com/my-svn-repo

    # svn commit
    svn commit


.. _Subversion Red Book: http://svnbook.red-bean.com/en/1.7/svn-book.html#svn.ref.svn

.. _Ask Ubuntu: http://askubuntu.com/questions/162391/how-do-i-fix-my-locale-issue