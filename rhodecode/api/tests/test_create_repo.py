# -*- coding: utf-8 -*-

# Copyright (C) 2010-2017  RhodeCode GmbH
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

import json

import mock
import pytest

from rhodecode.lib.utils2 import safe_unicode
from rhodecode.lib.vcs import settings
from rhodecode.model.meta import Session
from rhodecode.model.repo import RepoModel
from rhodecode.model.user import UserModel
from rhodecode.tests import TEST_USER_ADMIN_LOGIN
from rhodecode.api.tests.utils import (
    build_data, api_call, assert_ok, assert_error, crash)
from rhodecode.tests.fixture import Fixture


fixture = Fixture()


@pytest.mark.usefixtures("testuser_api", "app")
class TestCreateRepo(object):

    @pytest.mark.parametrize('given, expected_name, expected_exc', [
        ('api repo-1', 'api-repo-1', False),
        ('api-repo 1-ąć', 'api-repo-1-ąć', False),
        (u'unicode-ąć', u'unicode-ąć', False),
        ('some repo v1.2', 'some-repo-v1.2', False),
        ('v2.0', 'v2.0', False),
    ])
    def test_api_create_repo(self, backend, given, expected_name, expected_exc):

        id_, params = build_data(
            self.apikey,
            'create_repo',
            repo_name=given,
            owner=TEST_USER_ADMIN_LOGIN,
            repo_type=backend.alias,
        )
        response = api_call(self.app, params)

        ret = {
            'msg': 'Created new repository `%s`' % (expected_name,),
            'success': True,
            'task': None,
        }
        expected = ret
        assert_ok(id_, expected, given=response.body)

        repo = RepoModel().get_by_repo_name(safe_unicode(expected_name))
        assert repo is not None

        id_, params = build_data(self.apikey, 'get_repo', repoid=expected_name)
        response = api_call(self.app, params)
        body = json.loads(response.body)

        assert body['result']['enable_downloads'] is False
        assert body['result']['enable_locking'] is False
        assert body['result']['enable_statistics'] is False

        fixture.destroy_repo(safe_unicode(expected_name))

    def test_api_create_restricted_repo_type(self, backend):
        repo_name = 'api-repo-type-{0}'.format(backend.alias)
        id_, params = build_data(
            self.apikey,
            'create_repo',
            repo_name=repo_name,
            owner=TEST_USER_ADMIN_LOGIN,
            repo_type=backend.alias,
        )
        git_backend = settings.BACKENDS['git']
        with mock.patch(
                'rhodecode.lib.vcs.settings.BACKENDS', {'git': git_backend}):
            response = api_call(self.app, params)

        repo = RepoModel().get_by_repo_name(repo_name)

        if backend.alias == 'git':
            assert repo is not None
            expected = {
                'msg': 'Created new repository `{0}`'.format(repo_name,),
                'success': True,
                'task': None,
            }
            assert_ok(id_, expected, given=response.body)
        else:
            assert repo is None

        fixture.destroy_repo(repo_name)

    def test_api_create_repo_with_booleans(self, backend):
        repo_name = 'api-repo-2'
        id_, params = build_data(
            self.apikey,
            'create_repo',
            repo_name=repo_name,
            owner=TEST_USER_ADMIN_LOGIN,
            repo_type=backend.alias,
            enable_statistics=True,
            enable_locking=True,
            enable_downloads=True
        )
        response = api_call(self.app, params)

        repo = RepoModel().get_by_repo_name(repo_name)

        assert repo is not None
        ret = {
            'msg': 'Created new repository `%s`' % (repo_name,),
            'success': True,
            'task': None,
        }
        expected = ret
        assert_ok(id_, expected, given=response.body)

        id_, params = build_data(self.apikey, 'get_repo', repoid=repo_name)
        response = api_call(self.app, params)
        body = json.loads(response.body)

        assert body['result']['enable_downloads'] is True
        assert body['result']['enable_locking'] is True
        assert body['result']['enable_statistics'] is True

        fixture.destroy_repo(repo_name)

    def test_api_create_repo_in_group(self, backend):
        repo_group_name = 'my_gr'
        # create the parent
        fixture.create_repo_group(repo_group_name)

        repo_name = '%s/api-repo-gr' % (repo_group_name,)
        id_, params = build_data(
            self.apikey, 'create_repo',
            repo_name=repo_name,
            owner=TEST_USER_ADMIN_LOGIN,
            repo_type=backend.alias,)
        response = api_call(self.app, params)
        repo = RepoModel().get_by_repo_name(repo_name)
        assert repo is not None
        assert repo.group is not None

        ret = {
            'msg': 'Created new repository `%s`' % (repo_name,),
            'success': True,
            'task': None,
        }
        expected = ret
        assert_ok(id_, expected, given=response.body)
        fixture.destroy_repo(repo_name)
        fixture.destroy_repo_group(repo_group_name)

    def test_create_repo_in_group_that_doesnt_exist(self, backend, user_util):
        repo_group_name = 'fake_group'

        repo_name = '%s/api-repo-gr' % (repo_group_name,)
        id_, params = build_data(
            self.apikey, 'create_repo',
            repo_name=repo_name,
            owner=TEST_USER_ADMIN_LOGIN,
            repo_type=backend.alias,)
        response = api_call(self.app, params)

        expected = {'repo_group': 'Repository group `{}` does not exist'.format(
            repo_group_name)}
        assert_error(id_, expected, given=response.body)

    def test_api_create_repo_unknown_owner(self, backend):
        repo_name = 'api-repo-2'
        owner = 'i-dont-exist'
        id_, params = build_data(
            self.apikey, 'create_repo',
            repo_name=repo_name,
            owner=owner,
            repo_type=backend.alias)
        response = api_call(self.app, params)
        expected = 'user `%s` does not exist' % (owner,)
        assert_error(id_, expected, given=response.body)

    def test_api_create_repo_dont_specify_owner(self, backend):
        repo_name = 'api-repo-3'
        id_, params = build_data(
            self.apikey, 'create_repo',
            repo_name=repo_name,
            repo_type=backend.alias)
        response = api_call(self.app, params)

        repo = RepoModel().get_by_repo_name(repo_name)
        assert repo is not None
        ret = {
            'msg': 'Created new repository `%s`' % (repo_name,),
            'success': True,
            'task': None,
        }
        expected = ret
        assert_ok(id_, expected, given=response.body)
        fixture.destroy_repo(repo_name)

    def test_api_create_repo_by_non_admin(self, backend):
        repo_name = 'api-repo-4'
        id_, params = build_data(
            self.apikey_regular, 'create_repo',
            repo_name=repo_name,
            repo_type=backend.alias)
        response = api_call(self.app, params)

        repo = RepoModel().get_by_repo_name(repo_name)
        assert repo is not None
        ret = {
            'msg': 'Created new repository `%s`' % (repo_name,),
            'success': True,
            'task': None,
        }
        expected = ret
        assert_ok(id_, expected, given=response.body)
        fixture.destroy_repo(repo_name)

    def test_api_create_repo_by_non_admin_specify_owner(self, backend):
        repo_name = 'api-repo-5'
        owner = 'i-dont-exist'
        id_, params = build_data(
            self.apikey_regular, 'create_repo',
            repo_name=repo_name,
            repo_type=backend.alias,
            owner=owner)
        response = api_call(self.app, params)

        expected = 'Only RhodeCode super-admin can specify `owner` param'
        assert_error(id_, expected, given=response.body)
        fixture.destroy_repo(repo_name)

    def test_api_create_repo_by_non_admin_no_parent_group_perms(self, backend):
        repo_group_name = 'no-access'
        fixture.create_repo_group(repo_group_name)
        repo_name = 'no-access/api-repo'

        id_, params = build_data(
            self.apikey_regular, 'create_repo',
            repo_name=repo_name,
            repo_type=backend.alias)
        response = api_call(self.app, params)

        expected = {'repo_group': 'Repository group `{}` does not exist'.format(
            repo_group_name)}
        assert_error(id_, expected, given=response.body)
        fixture.destroy_repo_group(repo_group_name)
        fixture.destroy_repo(repo_name)

    def test_api_create_repo_non_admin_no_permission_to_create_to_root_level(
            self, backend, user_util):

        regular_user = user_util.create_user()
        regular_user_api_key = regular_user.api_key

        usr = UserModel().get_by_username(regular_user.username)
        usr.inherit_default_permissions = False
        Session().add(usr)

        repo_name = backend.new_repo_name()
        id_, params = build_data(
            regular_user_api_key, 'create_repo',
            repo_name=repo_name,
            repo_type=backend.alias)
        response = api_call(self.app, params)
        expected = {
            "repo_name": "You do not have the permission to "
                         "store repositories in the root location."}
        assert_error(id_, expected, given=response.body)

    def test_api_create_repo_exists(self, backend):
        repo_name = backend.repo_name
        id_, params = build_data(
            self.apikey, 'create_repo',
            repo_name=repo_name,
            owner=TEST_USER_ADMIN_LOGIN,
            repo_type=backend.alias,)
        response = api_call(self.app, params)
        expected = {
            'unique_repo_name': 'Repository with name `{}` already exists'.format(
                repo_name)}
        assert_error(id_, expected, given=response.body)

    @mock.patch.object(RepoModel, 'create', crash)
    def test_api_create_repo_exception_occurred(self, backend):
        repo_name = 'api-repo-6'
        id_, params = build_data(
            self.apikey, 'create_repo',
            repo_name=repo_name,
            owner=TEST_USER_ADMIN_LOGIN,
            repo_type=backend.alias,)
        response = api_call(self.app, params)
        expected = 'failed to create repository `%s`' % (repo_name,)
        assert_error(id_, expected, given=response.body)

    @pytest.mark.parametrize('parent_group, dirty_name, expected_name', [
        (None, 'foo bar x', 'foo-bar-x'),
        ('foo', '/foo//bar x', 'foo/bar-x'),
        ('foo-bar', 'foo-bar //bar x', 'foo-bar/bar-x'),
    ])
    def test_create_repo_with_extra_slashes_in_name(
            self, backend, parent_group, dirty_name, expected_name):

        if parent_group:
            gr = fixture.create_repo_group(parent_group)
            assert gr.group_name == parent_group

        id_, params = build_data(
            self.apikey, 'create_repo',
            repo_name=dirty_name,
            repo_type=backend.alias,
            owner=TEST_USER_ADMIN_LOGIN,)
        response = api_call(self.app, params)
        expected ={
           "msg": "Created new repository `{}`".format(expected_name),
           "task": None,
           "success": True
        }
        assert_ok(id_, expected, response.body)

        repo = RepoModel().get_by_repo_name(expected_name)
        assert repo is not None

        expected = {
            'msg': 'Created new repository `%s`' % (expected_name,),
            'success': True,
            'task': None,
        }
        assert_ok(id_, expected, given=response.body)
        fixture.destroy_repo(expected_name)
        if parent_group:
            fixture.destroy_repo_group(parent_group)
