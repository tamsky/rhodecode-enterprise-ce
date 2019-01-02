# -*- coding: utf-8 -*-

# Copyright (C) 2010-2019 RhodeCode GmbH
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


import pytest

from rhodecode.model.scm import ScmModel
from rhodecode.api.tests.utils import build_data, api_call, assert_ok


@pytest.fixture
def http_host_stub():
    """
    To ensure that we can get an IP address, this test shall run with a
    hostname set to "localhost".
    """
    return 'localhost:80'


@pytest.mark.usefixtures("testuser_api", "app")
class TestGetServerInfo(object):
    def test_api_get_server_info(self):
        id_, params = build_data(self.apikey, 'get_server_info')
        response = api_call(self.app, params)
        resp = response.json
        expected = ScmModel().get_server_info()
        expected['memory'] = resp['result']['memory']
        expected['uptime'] = resp['result']['uptime']
        expected['load'] = resp['result']['load']
        expected['cpu'] = resp['result']['cpu']
        expected['storage'] = resp['result']['storage']
        expected['storage_temp'] = resp['result']['storage_temp']
        expected['storage_inodes'] = resp['result']['storage_inodes']
        expected['server'] = resp['result']['server']

        expected['index_storage'] = resp['result']['index_storage']
        expected['storage'] = resp['result']['storage']

        assert_ok(id_, expected, given=response.body)

    def test_api_get_server_info_ip(self):
        id_, params = build_data(self.apikey, 'get_server_info')
        response = api_call(self.app, params)
        resp = response.json
        expected = ScmModel().get_server_info({'SERVER_NAME': 'unknown'})
        expected['memory'] = resp['result']['memory']
        expected['uptime'] = resp['result']['uptime']
        expected['load'] = resp['result']['load']
        expected['cpu'] = resp['result']['cpu']
        expected['storage'] = resp['result']['storage']
        expected['storage_temp'] = resp['result']['storage_temp']
        expected['storage_inodes'] = resp['result']['storage_inodes']
        expected['server'] = resp['result']['server']

        expected['index_storage'] = resp['result']['index_storage']
        expected['storage'] = resp['result']['storage']

        assert_ok(id_, expected, given=response.body)

    def test_api_get_server_info_data_for_search_index_build(self):
        id_, params = build_data(self.apikey, 'get_server_info')
        response = api_call(self.app, params)
        resp = response.json

        # required by indexer
        assert resp['result']['index_storage']
        assert resp['result']['storage']
