# -*- coding: utf-8 -*-

# Copyright (C) 2016-2019 RhodeCode GmbH
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
import formencode
import formencode.htmlfill

from pyramid.httpexceptions import HTTPFound, HTTPForbidden
from pyramid.view import view_config
from pyramid.renderers import render
from pyramid.response import Response

from rhodecode import events
from rhodecode.apps._base import BaseAppView, DataGridAppView

from rhodecode.lib.ext_json import json
from rhodecode.lib.auth import (
    LoginRequired, CSRFRequired, NotAnonymous,
    HasPermissionAny, HasRepoGroupPermissionAny)
from rhodecode.lib import helpers as h, audit_logger
from rhodecode.lib.utils2 import safe_int, safe_unicode
from rhodecode.model.forms import RepoGroupForm
from rhodecode.model.repo_group import RepoGroupModel
from rhodecode.model.scm import RepoGroupList
from rhodecode.model.db import Session, RepoGroup

log = logging.getLogger(__name__)


class AdminRepoGroupsView(BaseAppView, DataGridAppView):

    def load_default_context(self):
        c = self._get_local_tmpl_context()

        return c

    def _load_form_data(self, c):
        allow_empty_group = False

        if self._can_create_repo_group():
            # we're global admin, we're ok and we can create TOP level groups
            allow_empty_group = True

        # override the choices for this form, we need to filter choices
        # and display only those we have ADMIN right
        groups_with_admin_rights = RepoGroupList(
            RepoGroup.query().all(),
            perm_set=['group.admin'])
        c.repo_groups = RepoGroup.groups_choices(
            groups=groups_with_admin_rights,
            show_empty_group=allow_empty_group)

    def _can_create_repo_group(self, parent_group_id=None):
        is_admin = HasPermissionAny('hg.admin')('group create controller')
        create_repo_group = HasPermissionAny(
            'hg.repogroup.create.true')('group create controller')
        if is_admin or (create_repo_group and not parent_group_id):
            # we're global admin, or we have global repo group create
            # permission
            # we're ok and we can create TOP level groups
            return True
        elif parent_group_id:
            # we check the permission if we can write to parent group
            group = RepoGroup.get(parent_group_id)
            group_name = group.group_name if group else None
            if HasRepoGroupPermissionAny('group.admin')(
                    group_name, 'check if user is an admin of group'):
                # we're an admin of passed in group, we're ok.
                return True
            else:
                return False
        return False

    @LoginRequired()
    @NotAnonymous()
    # perms check inside
    @view_config(
        route_name='repo_groups', request_method='GET',
        renderer='rhodecode:templates/admin/repo_groups/repo_groups.mako')
    def repo_group_list(self):
        c = self.load_default_context()

        repo_group_list = RepoGroup.get_all_repo_groups()
        repo_group_list_acl = RepoGroupList(
            repo_group_list, perm_set=['group.admin'])
        repo_group_data = RepoGroupModel().get_repo_groups_as_dict(
            repo_group_list=repo_group_list_acl, admin=True)
        c.data = json.dumps(repo_group_data)
        return self._get_template_context(c)

    @LoginRequired()
    @NotAnonymous()
    # perm checks inside
    @view_config(
        route_name='repo_group_new', request_method='GET',
        renderer='rhodecode:templates/admin/repo_groups/repo_group_add.mako')
    def repo_group_new(self):
        c = self.load_default_context()

        # perm check for admin, create_group perm or admin of parent_group
        parent_group_id = safe_int(self.request.GET.get('parent_group'))
        if not self._can_create_repo_group(parent_group_id):
            raise HTTPForbidden()

        self._load_form_data(c)

        defaults = {}  # Future proof for default of repo group
        data = render(
            'rhodecode:templates/admin/repo_groups/repo_group_add.mako',
            self._get_template_context(c), self.request)
        html = formencode.htmlfill.render(
            data,
            defaults=defaults,
            encoding="UTF-8",
            force_defaults=False
        )
        return Response(html)

    @LoginRequired()
    @NotAnonymous()
    @CSRFRequired()
    # perm checks inside
    @view_config(
        route_name='repo_group_create', request_method='POST',
        renderer='rhodecode:templates/admin/repo_groups/repo_group_add.mako')
    def repo_group_create(self):
        c = self.load_default_context()
        _ = self.request.translate

        parent_group_id = safe_int(self.request.POST.get('group_parent_id'))
        can_create = self._can_create_repo_group(parent_group_id)

        self._load_form_data(c)
        # permissions for can create group based on parent_id are checked
        # here in the Form
        available_groups = map(lambda k: safe_unicode(k[0]), c.repo_groups)
        repo_group_form = RepoGroupForm(
            self.request.translate, available_groups=available_groups,
            can_create_in_root=can_create)()

        repo_group_name = self.request.POST.get('group_name')
        try:
            owner = self._rhodecode_user
            form_result = repo_group_form.to_python(dict(self.request.POST))
            copy_permissions = form_result.get('group_copy_permissions')
            repo_group = RepoGroupModel().create(
                group_name=form_result['group_name_full'],
                group_description=form_result['group_description'],
                owner=owner.user_id,
                copy_permissions=form_result['group_copy_permissions']
            )
            Session().flush()

            repo_group_data = repo_group.get_api_data()
            audit_logger.store_web(
                'repo_group.create', action_data={'data': repo_group_data},
                user=self._rhodecode_user)

            Session().commit()

            _new_group_name = form_result['group_name_full']

            repo_group_url = h.link_to(
                _new_group_name,
                h.route_path('repo_group_home', repo_group_name=_new_group_name))
            h.flash(h.literal(_('Created repository group %s')
                    % repo_group_url), category='success')

        except formencode.Invalid as errors:
            data = render(
                'rhodecode:templates/admin/repo_groups/repo_group_add.mako',
                self._get_template_context(c), self.request)
            html = formencode.htmlfill.render(
                data,
                defaults=errors.value,
                errors=errors.error_dict or {},
                prefix_error=False,
                encoding="UTF-8",
                force_defaults=False
            )
            return Response(html)
        except Exception:
            log.exception("Exception during creation of repository group")
            h.flash(_('Error occurred during creation of repository group %s')
                    % repo_group_name, category='error')
            raise HTTPFound(h.route_path('home'))

        affected_user_ids = [self._rhodecode_user.user_id]
        if copy_permissions:
            user_group_perms = repo_group.permissions(expand_from_user_groups=True)
            copy_perms = [perm['user_id'] for perm in user_group_perms]
            # also include those newly created by copy
            affected_user_ids.extend(copy_perms)
        events.trigger(events.UserPermissionsChange(affected_user_ids))

        raise HTTPFound(
            h.route_path('repo_group_home',
                         repo_group_name=form_result['group_name_full']))
