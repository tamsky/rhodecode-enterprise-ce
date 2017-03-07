# -*- coding: utf-8 -*-

# Copyright (C) 2016-2017  RhodeCode GmbH
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


from rhodecode.apps.admin.navigation import NavigationRegistry
from rhodecode.config.routing import ADMIN_PREFIX
from rhodecode.lib.utils2 import str2bool


def includeme(config):
    settings = config.get_settings()

    # Create admin navigation registry and add it to the pyramid registry.
    labs_active = str2bool(settings.get('labs_settings_active', False))
    navigation_registry = NavigationRegistry(labs_active=labs_active)
    config.registry.registerUtility(navigation_registry)

    config.add_route(
        name='admin_settings_open_source',
        pattern=ADMIN_PREFIX + '/settings/open_source')
    config.add_route(
        name='admin_settings_vcs_svn_generate_cfg',
        pattern=ADMIN_PREFIX + '/settings/vcs/svn_generate_cfg')

    config.add_route(
        name='admin_settings_system',
        pattern=ADMIN_PREFIX + '/settings/system')
    config.add_route(
        name='admin_settings_system_update',
        pattern=ADMIN_PREFIX + '/settings/system/updates')

    config.add_route(
        name='admin_settings_sessions',
        pattern=ADMIN_PREFIX + '/settings/sessions')
    config.add_route(
        name='admin_settings_sessions_cleanup',
        pattern=ADMIN_PREFIX + '/settings/sessions/cleanup')

    # users admin
    config.add_route(
        name='users',
        pattern=ADMIN_PREFIX + '/users')

    config.add_route(
        name='users_data',
        pattern=ADMIN_PREFIX + '/users_data')

    # user auth tokens
    config.add_route(
        name='edit_user_auth_tokens',
        pattern=ADMIN_PREFIX + '/users/{user_id:\d+}/edit/auth_tokens')
    config.add_route(
        name='edit_user_auth_tokens_add',
        pattern=ADMIN_PREFIX + '/users/{user_id:\d+}/edit/auth_tokens/new')
    config.add_route(
        name='edit_user_auth_tokens_delete',
        pattern=ADMIN_PREFIX + '/users/{user_id:\d+}/edit/auth_tokens/delete')

    # Scan module for configuration decorators.
    config.scan()
