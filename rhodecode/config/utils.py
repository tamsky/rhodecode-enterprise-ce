# -*- coding: utf-8 -*-

# Copyright (C) 2010-2017 RhodeCode GmbH
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

import os
import shlex
import Pyro4
import platform

from rhodecode.model import init_model


def configure_pyro4(config):
    """
    Configure Pyro4 based on `config`.

    This will mainly set the different configuration parameters of the Pyro4
    library based on the settings in our INI files. The Pyro4 documentation
    lists more details about the specific settings and their meaning.
    """
    Pyro4.config.COMMTIMEOUT = float(config['vcs.connection_timeout'])
    Pyro4.config.SERIALIZER = 'pickle'
    Pyro4.config.SERIALIZERS_ACCEPTED.add('pickle')

    # Note: We need server configuration in the WSGI processes
    # because we provide a callback server in certain vcs operations.
    Pyro4.config.SERVERTYPE = "multiplex"
    Pyro4.config.POLLTIMEOUT = 0.01


def configure_vcs(config):
    """
    Patch VCS config with some RhodeCode specific stuff
    """
    from rhodecode.lib.vcs import conf
    conf.settings.BACKENDS = {
        'hg': 'rhodecode.lib.vcs.backends.hg.MercurialRepository',
        'git': 'rhodecode.lib.vcs.backends.git.GitRepository',
        'svn': 'rhodecode.lib.vcs.backends.svn.SubversionRepository',
    }

    conf.settings.HOOKS_PROTOCOL = config['vcs.hooks.protocol']
    conf.settings.HOOKS_DIRECT_CALLS = config['vcs.hooks.direct_calls']
    conf.settings.GIT_REV_FILTER = shlex.split(config['git_rev_filter'])
    conf.settings.DEFAULT_ENCODINGS = config['default_encoding']
    conf.settings.ALIASES[:] = config['vcs.backends']
    conf.settings.SVN_COMPATIBLE_VERSION = config['vcs.svn.compatible_version']


def initialize_database(config):
    from rhodecode.lib.utils2 import engine_from_config, get_encryption_key
    engine = engine_from_config(config, 'sqlalchemy.db1.')
    init_model(engine, encryption_key=get_encryption_key(config))


def initialize_test_environment(settings, test_env=None):
    if test_env is None:
        test_env = not int(os.environ.get('RC_NO_TMP_PATH', 0))

    from rhodecode.lib.utils import (
        create_test_directory, create_test_database, create_test_repositories,
        create_test_index)
    from rhodecode.tests import TESTS_TMP_PATH
    # test repos
    if test_env:
        create_test_directory(TESTS_TMP_PATH)
        create_test_database(TESTS_TMP_PATH, settings)
        create_test_repositories(TESTS_TMP_PATH, settings)
        create_test_index(TESTS_TMP_PATH, settings)


def get_vcs_server_protocol(config):
    return config['vcs.server.protocol']


def set_instance_id(config):
    """ Sets a dynamic generated config['instance_id'] if missing or '*' """

    config['instance_id'] = config.get('instance_id') or ''
    if config['instance_id'] == '*' or not config['instance_id']:
        _platform_id = platform.uname()[1] or 'instance'
        config['instance_id'] = '%s-%s' % (_platform_id, os.getpid())
