
==============================
 Generate the Nix expressions
==============================

Details can be found in the repository of `RhodeCode Enterprise CE`_ inside of
the file `docs/contributing/dependencies.rst`.

Start the environment as follows:

.. code:: shell

   nix-shell pkgs/shell-generate.nix



Python dependencies
===================

.. code:: shell

   pip2nix generate --licenses
   # or
   nix-shell pkgs/shell-generate.nix --command "pip2nix generate --licenses"


NodeJS dependencies
===================

Generate node-packages.nix file with all dependencies from NPM and package.json file
This should be run before entering nix-shell.

The sed at the end fixes a bug with http rewrite of re-generated packages

.. code:: shell

   rm -rf node_modules &&
   nix-shell pkgs/shell-generate.nix --command "
       node2nix --input package.json \
                -o pkgs/node-packages.nix \
                -e pkgs/node-env.nix \
                -c pkgs/node-default.nix \
                -d --flatten --nodejs-8 " &&
   sed -i -e 's/http:\/\//https:\/\//g' pkgs/node-packages.nix


Generate license data
=====================

.. code:: shell

   nix-build pkgs/license-generate.nix -o result-license && cat result-license/licenses.json | python -m json.tool > rhodecode/config/licenses.json


.. Links

.. _RhodeCode Enterprise CE: https://code.rhodecode.com/rhodecode-enterprise-ce
