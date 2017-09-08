# -*- coding: utf-8 -*-

# Copyright (C) 2017-2017 RhodeCode GmbH
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

from pyramid.httpexceptions import HTTPFound
from pyramid.view import view_config

from rhodecode.apps._base import RepoAppView
from rhodecode.lib import helpers as h
from rhodecode.lib.auth import (
    LoginRequired, CSRFRequired, HasRepoPermissionAnyDecorator)
from rhodecode.model.scm import ScmModel

log = logging.getLogger(__name__)


class RepoSettingsRemoteView(RepoAppView):
    def load_default_context(self):
        c = self._get_local_tmpl_context()

        self._register_global_c(c)
        return c

    @LoginRequired()
    @HasRepoPermissionAnyDecorator('repository.admin')
    @view_config(
        route_name='edit_repo_remote', request_method='GET',
        renderer='rhodecode:templates/admin/repos/repo_edit.mako')
    def repo_remote_edit_form(self):
        c = self.load_default_context()
        c.active = 'remote'

        return self._get_template_context(c)

    @LoginRequired()
    @HasRepoPermissionAnyDecorator('repository.admin')
    @CSRFRequired()
    @view_config(
        route_name='edit_repo_remote_pull', request_method='POST',
        renderer=None)
    def repo_remote_pull_changes(self):
        _ = self.request.translate
        self.load_default_context()

        try:
            ScmModel().pull_changes(
                self.db_repo_name, self._rhodecode_user.username)
            h.flash(_('Pulled from remote location'), category='success')
        except Exception:
            log.exception("Exception during pull from remote")
            h.flash(_('An error occurred during pull from remote location'),
                    category='error')
        raise HTTPFound(
            h.route_path('edit_repo_remote', repo_name=self.db_repo_name))
