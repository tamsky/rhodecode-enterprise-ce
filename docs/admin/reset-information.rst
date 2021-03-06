.. _rhodecode-reset-ref:

Settings Management
-------------------

All |RCE| settings can be set from the user interface, but in the event that
it somehow becomes unavailable you can use ``ishell`` inside your |RCE|
``virtualenv`` to carry out emergency measures.

.. warning::

   Logging into the |RCE| database with ``iShell`` should only be done by an
   experienced and knowledgeable database administrator.


Reset Admin Account Privileges
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you accidentally remove your admin privileges from the admin account you
can restore them using ``ishell``. Use the following example to reset your
account permissions.

.. code-block:: bash

    # Open iShell from the terminal
    $ rccontrol ishell enterprise-1

.. code-block:: mysql

    # Use this example to change user permissions
    In [1]: adminuser = User.get_by_username('username')
    In [2]: adminuser.admin = True
    In [3]: Session().add(adminuser);Session().commit()
    In [4]: exit()


Set to read global ``.hgrc`` file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

By default, |RCE| does not read global ``hgrc`` files in
``/etc/mercurial/hgrc`` or ``/etc/mercurial/hgrc.d`` because it
can lead to issues. This is set in the ``rhodecode_ui`` table for which
there is no UI. If you need to edit this you can
manually change the settings using SQL statements with ``ishell``. Use the
following example to make changes to this table.

.. code-block:: bash

  # Open iShell from the terminal
  $ rccontrol ishell enterprise-1

.. code-block:: mysql

  # Use this example to enable global .hgrc access
  In [1]: new_option = RhodeCodeUi()
  In [2]: new_option.ui_section='web'
  In [3]: new_option.ui_key='allow_push'
  In [4]: new_option.ui_value='*'
  In [5]: Session().add(new_option);Session().commit()
  In [6]: exit()


Manually Reset Password
^^^^^^^^^^^^^^^^^^^^^^^

If you need to manually reset a user password, use the following steps.

1. Navigate to your |RCE| install location.
2. Run the interactive ``ishell`` prompt.
3. Set a new password.

Use the following code example to carry out these steps.

.. code-block:: bash

    # starts the ishell interactive prompt
    $ rccontrol ishell enterprise-1

.. code-block:: mysql

    In [1]: from rhodecode.lib.auth import generate_auth_token
    In [2]: from rhodecode.lib.auth import get_crypt_password
    # Enter the user name whose password you wish to change
    In [3]: my_user = 'USERNAME'
    In [4]: u = User.get_by_username(my_user)
    # If this fails then the user does not exist
    In [5]: u.auth_token = generate_auth_token(my_user)
    # Set the new password
    In [6]: u.password = get_crypt_password('PASSWORD')
    In [7]: Session().add(u);Session().commit()
    In [8]: exit()


Change user details
^^^^^^^^^^^^^^^^^^^

If you need to manually change some of users details, use the following steps.

1. Navigate to your |RCE| install location.
2. Run the interactive ``ishell`` prompt.
3. Set a new arguments for users.

Use the following code example to carry out these steps.

.. code-block:: bash

    # starts the ishell interactive prompt
    $ rccontrol ishell enterprise-1

.. code-block:: mysql

    # Use this example to change email and username of LDAP user
    In [1]: my_user = User.get_by_username('some_username')
    In [2]: my_user.email = 'new_email@foobar.com'
    In [3]: my_user.username = 'SomeUser'
    In [4]: Session().add(my_user);Session().commit()
    In [5]: exit()


Change user login type
^^^^^^^^^^^^^^^^^^^^^^

Sometimes it's required to change account type from RhodeCode to LDAP or
other external authentication type.
If you need to manually change the method of login, use the following steps.

1. Navigate to your |RCE| install location.
2. Run the interactive ``ishell`` prompt.
3. Set a new arguments for users.

Use the following code example to carry out these steps.
Available values for new_extern_type can be found when browsing available
authentication types in RhodeCode admin interface for authentication.
Use the text which is shown after '#' sign, eg.
` LDAP (egg:rhodecode-enterprise-ce#ldap)` it's type is 'ldap'

.. code-block:: bash

    # starts the ishell interactive prompt
    $ rccontrol ishell enterprise-1

.. code-block:: mysql

    # Use this example to change users from authentication
    # using rhodecode internal to ldap
    In [1]: new_extern_type = 'ldap'
    In [2]: my_user = User.get_by_username('some_username')
    In [3]: my_user.extern_type = new_extern_type
    In [4]: my_user.extern_name = new_extern_type
    In [5]: Session().add(my_user);Session().commit()
    In [6]: exit()
