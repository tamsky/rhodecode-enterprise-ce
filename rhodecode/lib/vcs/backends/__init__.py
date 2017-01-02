# -*- coding: utf-8 -*-

# Copyright (C) 2014-2017 RhodeCode GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License, version 3
# (only), as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program is dual-licensed. If you wish to learn more about the
# RhodeCode Enterprise Edition, including its added features, Support services,
# and proprietary license terms, please see https://rhodecode.com/licenses/

"""
VCS Backends module
"""

import os
import logging

from pprint import pformat

from rhodecode.lib.vcs.conf import settings
from rhodecode.lib.vcs.exceptions import VCSError
from rhodecode.lib.vcs.utils.helpers import get_scm
from rhodecode.lib.vcs.utils.imports import import_class


log = logging.getLogger(__name__)


def get_vcs_instance(repo_path, *args, **kwargs):
    """
    Given a path to a repository an instance of the corresponding vcs backend
    repository class is created and returned. If no repository can be found
    for the path it returns None. Arguments and keyword arguments are passed
    to the vcs backend repository class.
    """
    from rhodecode.lib.utils2 import safe_str

    explicit_vcs_alias = kwargs.pop('_vcs_alias', None)
    try:
        vcs_alias = safe_str(explicit_vcs_alias or get_scm(repo_path)[0])
        log.debug(
            'Creating instance of %s repository from %s', vcs_alias,
            safe_str(repo_path))
        backend = get_backend(vcs_alias)

        if explicit_vcs_alias:
            # do final verification of existance of the path, this does the
            # same as get_scm() call which we skip in explicit_vcs_alias
            if not os.path.isdir(repo_path):
                raise VCSError("Given path %s is not a directory" % repo_path)
    except VCSError:
        log.exception(
            'Perhaps this repository is in db and not in '
            'filesystem run rescan repositories with '
            '"destroy old data" option from admin panel')
        return None

    return backend(repo_path=repo_path, *args, **kwargs)


def get_backend(alias):
    """
    Returns ``Repository`` class identified by the given alias or raises
    VCSError if alias is not recognized or backend class cannot be imported.
    """
    if alias not in settings.BACKENDS:
        raise VCSError(
            "Given alias '%s' is not recognized! Allowed aliases:\n%s" %
            (alias, pformat(settings.BACKENDS.keys())))
    backend_path = settings.BACKENDS[alias]
    klass = import_class(backend_path)
    return klass


def get_supported_backends():
    """
    Returns list of aliases of supported backends.
    """
    return settings.BACKENDS.keys()


def get_vcsserver_version():
    from rhodecode.lib.vcs import connection
    data = connection.Service.get_vcsserver_service_data()
    if data and 'version' in data:
        return data['version']

    return None
