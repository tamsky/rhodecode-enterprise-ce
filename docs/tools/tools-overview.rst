.. _tools-overview:

|RCT| Overview
--------------

To install |RCT| correctly, see the installation steps covered in
:ref:`install-tools`, and :ref:`config-rhoderc`.

Once |RCT| is installed, and the :file:`/home/{user}/.rhoderc` file is
configured you can then use |RCT| on each |RCE| instance to carry out admin
tasks. Use the following example to configure that file,
and once configured see the :ref:`tools-cli` for more details.

.. note::

   |RCT| require |PY| 2.7 to run.

.. code-block:: bash

    # Get the status of each instance you wish to use with Tools
    (venv)brian@ubuntu:~$ rccontrol status

     - NAME: momentum-1
     - STATUS: RUNNING
     - TYPE: Momentum
     - VERSION: 3.0.0-nightly-momentum
     - URL: http://127.0.0.1:10003

     - NAME: momentum-3
     - STATUS: RUNNING
     - TYPE: Momentum
     - VERSION: 3.0.0-nightly-momentum
     - URL: http://127.0.0.1:10007

Example :file:`/home/{user}/.rhoderc` file.

.. code-block:: ini

    # Configure the .rhoderc file for each instance
    # API keys found in your instance
    [instance:enterprise-1]
    api_host = http://127.0.0.1:10003/
    api_key = 91fdbdc257289c46633ef5aab274412911de1ba9
    repo_dir = /home/brian/repos

    [instance:enterprise-3]
    api_host = http://127.0.0.1:10007/
    api_key = 5a925f65438d29f8d6ced8ab8e8c3d305998d1d9
    repo_dir = /home/brian/testing-repos/


Example usage of |RCT| after |RCE| 3.5.0. From this version onwards |RCT| is
packaged with |RCE| by default.

.. code-block:: bash

    $ .rccontrol/enterprise-4/profile/bin/rhodecode-api --instance-name=enterprise-4 get_ip                                                                                                                                                                                                                                                                                                                                                                     [11:56:57 on 05/10/2018]

    {
      "error": null,
      "id": 1000,
      "result": {
        "server_ip_addr": "1.2.3.4",
        "user_ips": []
      }
    }
