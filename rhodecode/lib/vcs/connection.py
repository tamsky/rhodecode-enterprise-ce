# -*- coding: utf-8 -*-

# Copyright (C) 2014-2018 RhodeCode GmbH
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
Holds connection for remote server.
"""


def _not_initialized(*args, **kwargs):
    """Placeholder for objects which have to be initialized first."""
    raise Exception(
        "rhodecode.lib.vcs is not yet initialized. "
        "Make sure `vcs.server` is enabled in your configuration.")

# TODO: figure out a nice default value for these things
Service = _not_initialized

Git = _not_initialized
Hg = _not_initialized
Svn = _not_initialized
