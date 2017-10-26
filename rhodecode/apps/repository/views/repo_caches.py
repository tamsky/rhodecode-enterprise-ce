# -*- coding: utf-8 -*-

# Copyright (C) 2011-2017 RhodeCode GmbH
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
from rhodecode.lib.auth import LoginRequired, HasRepoPermissionAnyDecorator, \
    CSRFRequired
from rhodecode.lib import helpers as h
from rhodecode.model.meta import Session
from rhodecode.model.scm import ScmModel

log = logging.getLogger(__name__)


class RepoCachesView(RepoAppView):
    def load_default_context(self):
        c = self._get_local_tmpl_context()

        # TODO(marcink): remove repo_info and use c.rhodecode_db_repo instead
        c.repo_info = self.db_repo

        self._register_global_c(c)
        return c

    @LoginRequired()
    @HasRepoPermissionAnyDecorator('repository.admin')
    @view_config(
        route_name='edit_repo_caches', request_method='GET',
        renderer='rhodecode:templates/admin/repos/repo_edit.mako')
    def repo_caches(self):
        c = self.load_default_context()
        c.active = 'caches'

        return self._get_template_context(c)

    @LoginRequired()
    @HasRepoPermissionAnyDecorator('repository.admin')
    @CSRFRequired()
    @view_config(
        route_name='edit_repo_caches', request_method='POST')
    def repo_caches_purge(self):
        _ = self.request.translate
        c = self.load_default_context()
        c.active = 'caches'

        try:
            ScmModel().mark_for_invalidation(self.db_repo_name, delete=True)
            Session().commit()
            h.flash(_('Cache invalidation successful'),
                    category='success')
        except Exception:
            log.exception("Exception during cache invalidation")
            h.flash(_('An error occurred during cache invalidation'),
                    category='error')

        raise HTTPFound(h.route_path(
            'edit_repo_caches', repo_name=self.db_repo_name))