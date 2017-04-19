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
from pylons import tmpl_context as c

import rhodecode
from rhodecode.model.db import Repository, User
from rhodecode.model.meta import Session
from rhodecode.model.repo import RepoModel
from rhodecode.model.repo_group import RepoGroupModel
from rhodecode.model.settings import SettingsModel
from rhodecode.tests import TestController, url
from rhodecode.tests.fixture import Fixture


fixture = Fixture()


class TestHomeController(TestController):

    def test_index(self):
        self.log_user()
        response = self.app.get(url(controller='home', action='index'))
        # if global permission is set
        response.mustcontain('Add Repository')

        # search for objects inside the JavaScript JSON
        for repo in Repository.getAll():
            response.mustcontain('"name_raw": "%s"' % repo.repo_name)

    def test_index_contains_statics_with_ver(self):
        self.log_user()
        response = self.app.get(url(controller='home', action='index'))

        rhodecode_version_hash = c.rhodecode_version_hash
        response.mustcontain('style.css?ver={0}'.format(rhodecode_version_hash))
        response.mustcontain('rhodecode-components.js?ver={0}'.format(rhodecode_version_hash))

    def test_index_contains_backend_specific_details(self, backend):
        self.log_user()
        response = self.app.get(url(controller='home', action='index'))
        tip = backend.repo.get_commit().raw_id

        # html in javascript variable:
        response.mustcontain(r'<i class=\"icon-%s\"' % (backend.alias, ))
        response.mustcontain(r'href=\"/%s\"' % (backend.repo_name, ))

        response.mustcontain("""/%s/changeset/%s""" % (backend.repo_name, tip))
        response.mustcontain("""Added a symlink""")

    def test_index_with_anonymous_access_disabled(self):
        with fixture.anon_access(False):
            response = self.app.get(url(controller='home', action='index'),
                                    status=302)
            assert 'login' in response.location

    def test_index_page_on_groups(self, autologin_user, repo_group):
        response = self.app.get(url('repo_group_home', group_name='gr1'))
        response.mustcontain("gr1/repo_in_group")

    def test_index_page_on_group_with_trailing_slash(
            self, autologin_user, repo_group):
        response = self.app.get(url('repo_group_home', group_name='gr1') + '/')
        response.mustcontain("gr1/repo_in_group")

    @pytest.fixture(scope='class')
    def repo_group(self, request):
        gr = fixture.create_repo_group('gr1')
        fixture.create_repo(name='gr1/repo_in_group', repo_group=gr)

        @request.addfinalizer
        def cleanup():
            RepoModel().delete('gr1/repo_in_group')
            RepoGroupModel().delete(repo_group='gr1', force_delete=True)
            Session().commit()

    def test_index_with_name_with_tags(self, autologin_user):
        user = User.get_by_username('test_admin')
        user.name = '<img src="/image1" onload="alert(\'Hello, World!\');">'
        user.lastname = (
            '<img src="/image2" onload="alert(\'Hello, World!\');">')
        Session().add(user)
        Session().commit()

        response = self.app.get(url(controller='home', action='index'))
        response.mustcontain(
            '&lt;img src=&#34;/image1&#34; onload=&#34;'
            'alert(&#39;Hello, World!&#39;);&#34;&gt;')
        response.mustcontain(
            '&lt;img src=&#34;/image2&#34; onload=&#34;'
            'alert(&#39;Hello, World!&#39;);&#34;&gt;')

    @pytest.mark.parametrize("name, state", [
        ('Disabled', False),
        ('Enabled', True),
    ])
    def test_index_show_version(self, autologin_user, name, state):
        version_string = 'RhodeCode Enterprise %s' % rhodecode.__version__

        sett = SettingsModel().create_or_update_setting(
            'show_version', state, 'bool')
        Session().add(sett)
        Session().commit()
        SettingsModel().invalidate_settings_cache()

        response = self.app.get(url(controller='home', action='index'))
        if state is True:
            response.mustcontain(version_string)
        if state is False:
            response.mustcontain(no=[version_string])
