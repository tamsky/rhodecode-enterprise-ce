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
Login and cookies session model for RhodeCode
"""

import logging

from pylons import session, tmpl_context as c
from rhodecode.model import BaseModel


log = logging.getLogger(__name__)


class LoginSession(BaseModel):
    cls = None

    def destroy_user_session(self):
        cur_user = c.rhodecode_user
        log.info('Deleting session for user: `%s`', cur_user)
        session.delete()

