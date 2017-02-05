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


import pytest

from rhodecode.model.repo import RepoModel
from rhodecode.api.tests.utils import (
    build_data, api_call, assert_ok, assert_error, jsonify)
from rhodecode.model.db import User


@pytest.mark.usefixtures("testuser_api", "app")
class TestGetRepos(object):
    def test_api_get_repos(self):
        id_, params = build_data(self.apikey, 'get_repos')
        response = api_call(self.app, params)

        result = []
        for repo in RepoModel().get_all():
            result.append(repo.get_api_data(include_secrets=True))
        ret = jsonify(result)

        expected = ret
        assert_ok(id_, expected, given=response.body)

    def test_api_get_repos_only_toplevel(self, user_util):
        repo_group = user_util.create_repo_group(auto_cleanup=True)
        user_util.create_repo(parent=repo_group)

        id_, params = build_data(self.apikey, 'get_repos', traverse=0)
        response = api_call(self.app, params)

        result = []
        for repo in RepoModel().get_repos_for_root(root=None):
            result.append(repo.get_api_data(include_secrets=True))
        expected = jsonify(result)

        assert_ok(id_, expected, given=response.body)

    def test_api_get_repos_with_wrong_root(self):
        id_, params = build_data(self.apikey, 'get_repos', root='abracadabra')
        response = api_call(self.app, params)

        expected = 'Root repository group `abracadabra` does not exist'
        assert_error(id_, expected, given=response.body)

    def test_api_get_repos_with_root(self, user_util):
        repo_group = user_util.create_repo_group(auto_cleanup=True)
        repo_group_name = repo_group.group_name

        user_util.create_repo(parent=repo_group)
        user_util.create_repo(parent=repo_group)

        # nested, should not show up
        user_util._test_name = '{}/'.format(repo_group_name)
        sub_repo_group = user_util.create_repo_group(auto_cleanup=True)
        user_util.create_repo(parent=sub_repo_group)

        id_, params = build_data(self.apikey, 'get_repos',
                                 root=repo_group_name, traverse=0)
        response = api_call(self.app, params)

        result = []
        for repo in RepoModel().get_repos_for_root(repo_group):
            result.append(repo.get_api_data(include_secrets=True))

        assert len(result) == 2
        expected = jsonify(result)
        assert_ok(id_, expected, given=response.body)

    def test_api_get_repos_with_root_and_traverse(self, user_util):
        repo_group = user_util.create_repo_group(auto_cleanup=True)
        repo_group_name = repo_group.group_name

        user_util.create_repo(parent=repo_group)
        user_util.create_repo(parent=repo_group)

        # nested, should not show up
        user_util._test_name = '{}/'.format(repo_group_name)
        sub_repo_group = user_util.create_repo_group(auto_cleanup=True)
        user_util.create_repo(parent=sub_repo_group)

        id_, params = build_data(self.apikey, 'get_repos',
                                 root=repo_group_name, traverse=1)
        response = api_call(self.app, params)

        result = []
        for repo in RepoModel().get_repos_for_root(
                repo_group_name, traverse=True):
            result.append(repo.get_api_data(include_secrets=True))

        assert len(result) == 3
        expected = jsonify(result)
        assert_ok(id_, expected, given=response.body)

    def test_api_get_repos_non_admin(self):
        id_, params = build_data(self.apikey_regular, 'get_repos')
        response = api_call(self.app, params)

        user = User.get_by_username(self.TEST_USER_LOGIN)
        allowed_repos = user.AuthUser.permissions['repositories']

        result = []
        for repo in RepoModel().get_all():
            perm = allowed_repos[repo.repo_name]
            if perm in ['repository.read', 'repository.write', 'repository.admin']:
                result.append(repo.get_api_data())
        ret = jsonify(result)

        expected = ret
        assert_ok(id_, expected, given=response.body)
