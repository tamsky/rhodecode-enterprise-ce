# -*- coding: utf-8 -*-

# Copyright (C) 2010-2018 RhodeCode GmbH
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

from rhodecode.tests.events.conftest import EventCatcher

from rhodecode.lib import hooks_base, utils2
from rhodecode.model.repo import RepoModel
from rhodecode.events.repo import (
    RepoPrePullEvent, RepoPullEvent,
    RepoPrePushEvent, RepoPushEvent,
    RepoPreCreateEvent, RepoCreateEvent,
    RepoPreDeleteEvent, RepoDeleteEvent,
)


@pytest.fixture
def scm_extras(user_regular, repo_stub):
    extras = utils2.AttributeDict({
        'ip': '127.0.0.1',
        'username': user_regular.username,
        'user_id': user_regular.user_id,
        'action': '',
        'repository': repo_stub.repo_name,
        'scm': repo_stub.scm_instance().alias,
        'config': '',
        'repo_store': '',
        'server_url': 'http://example.com',
        'make_lock': None,
        'user_agent': 'some-client',
        'locked_by': [None],
        'commit_ids': ['a' * 40] * 3,
        'hook_type': 'scm_extras_test',
        'is_shadow_repo': False,
    })
    return extras


# TODO: dan: make the serialization tests complete json comparisons
@pytest.mark.parametrize('EventClass', [
    RepoPreCreateEvent, RepoCreateEvent,
    RepoPreDeleteEvent, RepoDeleteEvent,
])
def test_repo_events_serialized(config_stub, repo_stub, EventClass):
    event = EventClass(repo_stub)
    data = event.as_dict()
    assert data['name'] == EventClass.name
    assert data['repo']['repo_name'] == repo_stub.repo_name
    assert data['repo']['url']
    assert data['repo']['permalink_url']


@pytest.mark.parametrize('EventClass', [
    RepoPrePullEvent, RepoPullEvent, RepoPrePushEvent
])
def test_vcs_repo_events_serialize(config_stub, repo_stub, scm_extras, EventClass):
    event = EventClass(repo_name=repo_stub.repo_name, extras=scm_extras)
    data = event.as_dict()
    assert data['name'] == EventClass.name
    assert data['repo']['repo_name'] == repo_stub.repo_name
    assert data['repo']['url']
    assert data['repo']['permalink_url']


@pytest.mark.parametrize('EventClass', [RepoPushEvent])
def test_vcs_repo_push_event_serialize(config_stub, repo_stub, scm_extras, EventClass):
    event = EventClass(repo_name=repo_stub.repo_name,
                       pushed_commit_ids=scm_extras['commit_ids'],
                       extras=scm_extras)
    data = event.as_dict()
    assert data['name'] == EventClass.name
    assert data['repo']['repo_name'] == repo_stub.repo_name
    assert data['repo']['url']
    assert data['repo']['permalink_url']


def test_create_delete_repo_fires_events(backend):
    with EventCatcher() as event_catcher:
        repo = backend.create_repo()
    assert event_catcher.events_types == [RepoPreCreateEvent, RepoCreateEvent]

    with EventCatcher() as event_catcher:
        RepoModel().delete(repo)
    assert event_catcher.events_types == [RepoPreDeleteEvent, RepoDeleteEvent]


def test_pull_fires_events(scm_extras):
    with EventCatcher() as event_catcher:
        hooks_base.pre_push(scm_extras)
    assert event_catcher.events_types == [RepoPrePushEvent]

    with EventCatcher() as event_catcher:
        hooks_base.post_push(scm_extras)
    assert event_catcher.events_types == [RepoPushEvent]


def test_push_fires_events(scm_extras):
    with EventCatcher() as event_catcher:
        hooks_base.pre_pull(scm_extras)
    assert event_catcher.events_types == [RepoPrePullEvent]

    with EventCatcher() as event_catcher:
        hooks_base.post_pull(scm_extras)
    assert event_catcher.events_types == [RepoPullEvent]

