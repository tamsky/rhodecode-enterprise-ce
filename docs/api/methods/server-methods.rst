.. _server-methods-ref:

server methods
=================

get_ip 
------

.. py:function:: get_ip(apiuser, userid=<Optional:<OptionalAttr:apiuser>>)

   Displays the IP Address as seen from the |RCE| server.

   * This command displays the IP Address, as well as all the defined IP
     addresses for the specified user. If the ``userid`` is not set, the
     data returned is for the user calling the method.

   This command can only be run using an |authtoken| with admin rights to
   the specified repository.

   This command takes the following options:

   :param apiuser: This is filled automatically from |authtoken|.
   :type apiuser: AuthUser
   :param userid: Sets the userid for which associated IP Address data
       is returned.
   :type userid: Optional(str or int)

   Example output:

   .. code-block:: bash

       id : <id_given_in_input>
       result : {
                    "server_ip_addr": "<ip_from_clien>",
                    "user_ips": [
                                   {
                                      "ip_addr": "<ip_with_mask>",
                                      "ip_range": ["<start_ip>", "<end_ip>"],
                                   },
                                   ...
                                ]
       }


get_server_info 
---------------

.. py:function:: get_server_info(apiuser)

   Returns the |RCE| server information.

   This includes the running version of |RCE| and all installed
   packages. This command takes the following options:

   :param apiuser: This is filled automatically from the |authtoken|.
   :type apiuser: AuthUser

   Example output:

   .. code-block:: bash

     id : <id_given_in_input>
     result : {
       'modules': [<module name>,...]
       'py_version': <python version>,
       'platform': <platform type>,
       'rhodecode_version': <rhodecode version>
     }
     error :  null


rescan_repos 
------------

.. py:function:: rescan_repos(apiuser, remove_obsolete=<Optional:False>)

   Triggers a rescan of the specified repositories.

   * If the ``remove_obsolete`` option is set, it also deletes repositories
     that are found in the database but not on the file system, so called
     "clean zombies".

   This command can only be run using an |authtoken| with admin rights to
   the specified repository.

   This command takes the following options:

   :param apiuser: This is filled automatically from the |authtoken|.
   :type apiuser: AuthUser
   :param remove_obsolete: Deletes repositories from the database that
       are not found on the filesystem.
   :type remove_obsolete: Optional(``True`` | ``False``)

   Example output:

   .. code-block:: bash

     id : <id_given_in_input>
     result : {
       'added': [<added repository name>,...]
       'removed': [<removed repository name>,...]
     }
     error :  null

   Example error output:

   .. code-block:: bash

     id : <id_given_in_input>
     result : null
     error :  {
       'Error occurred during rescan repositories action'
     }

