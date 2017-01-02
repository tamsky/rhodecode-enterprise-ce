# Copyright (C) 2016-2017 RhodeCode GmbH
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

from datetime import datetime
from pyramid.threadlocal import get_current_request
from rhodecode.lib.utils2 import AttributeDict


# this is a user object to be used for events caused by the system (eg. shell)
SYSTEM_USER = AttributeDict(dict(
    username='__SYSTEM__'
))


class RhodecodeEvent(object):
    """
    Base event class for all Rhodecode events
    """
    name = "RhodeCodeEvent"

    def __init__(self):
        self.request = get_current_request()
        self.utc_timestamp = datetime.utcnow()

    @property
    def actor(self):
        if self.request:
            return self.request.user.get_instance()
        return SYSTEM_USER

    @property
    def actor_ip(self):
        if self.request:
            return self.request.user.ip_addr
        return '<no ip available>'

    @property
    def server_url(self):
        if self.request:
            from rhodecode.lib import helpers as h
            return h.url('home', qualified=True)
        return '<no server_url available>'

    def as_dict(self):
        data = {
            'name': self.name,
            'utc_timestamp': self.utc_timestamp,
            'actor_ip': self.actor_ip,
            'actor': {
                'username': self.actor.username
            },
            'server_url': self.server_url
        }
        return data
