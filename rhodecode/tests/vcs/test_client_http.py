# -*- coding: utf-8 -*-

# Copyright (C) 2010-2016  RhodeCode GmbH
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

import logging

import mock
import msgpack
import pytest

from rhodecode.lib import vcs
from rhodecode.lib.vcs import client_http


def test_uses_persistent_http_connections(caplog, vcsbackend_hg):
    repo = vcsbackend_hg.repo
    remote_call = repo._remote.branches

    with caplog.at_level(logging.INFO):
        for x in range(5):
            remote_call(normal=True, closed=False)

    new_connections = [
        r for r in caplog.record_tuples() if is_new_connection(*r)]
    assert len(new_connections) <= 1


def is_new_connection(logger, level, message):
    return (
        logger == 'requests.packages.urllib3.connectionpool' and
        message.startswith('Starting new HTTP'))


@pytest.fixture
def stub_session():
    """
    Stub of `requests.Session()`.
    """
    session = mock.Mock()
    session.post().content = msgpack.packb({})
    session.reset_mock()
    return session


def test_repo_maker_uses_session_for_classmethods(stub_session):
    repo_maker = client_http.RepoMaker(
        'server_and_port', 'endpoint', stub_session)
    repo_maker.example_call()
    stub_session.post.assert_called_with(
        'http://server_and_port/endpoint', data=mock.ANY)


def test_repo_maker_uses_session_for_instance_methods(
        stub_session, config):
    repo_maker = client_http.RepoMaker(
        'server_and_port', 'endpoint', stub_session)
    repo = repo_maker('stub_path', config)
    repo.example_call()
    stub_session.post.assert_called_with(
        'http://server_and_port/endpoint', data=mock.ANY)


@mock.patch('rhodecode.lib.vcs.connection')
def test_connect_passes_in_the_same_session(connection, stub_session):
    session_factory_patcher = mock.patch.object(
        vcs, '_create_http_rpc_session', return_value=stub_session)
    with session_factory_patcher:
        vcs.connect_http('server_and_port')
    assert connection.Hg._session == stub_session
    assert connection.Svn._session == stub_session
    assert connection.Git._session == stub_session
