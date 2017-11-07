# -*- coding: utf-8 -*-

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

import logging

import peppercorn
import formencode
import formencode.htmlfill
from pyramid.httpexceptions import HTTPFound
from pyramid.view import view_config
from pyramid.response import Response
from pyramid.renderers import render

from rhodecode.lib.exceptions import (
    RepoGroupAssignmentError, UserGroupAssignedException)
from rhodecode.model.forms import (
    UserGroupPermsForm, UserGroupForm, UserIndividualPermissionsForm,
    UserPermissionsForm)
from rhodecode.model.permission import PermissionModel

from rhodecode.apps._base import UserGroupAppView
from rhodecode.lib.auth import (
    LoginRequired, HasUserGroupPermissionAnyDecorator, CSRFRequired)
from rhodecode.lib import helpers as h, audit_logger
from rhodecode.lib.utils2 import str2bool
from rhodecode.model.db import (
    joinedload, User, UserGroupRepoToPerm, UserGroupRepoGroupToPerm)
from rhodecode.model.meta import Session
from rhodecode.model.user_group import UserGroupModel

log = logging.getLogger(__name__)


class UserGroupsView(UserGroupAppView):

    def load_default_context(self):
        c = self._get_local_tmpl_context()

        PermissionModel().set_global_permission_choices(
            c, gettext_translator=self.request.translate)

        self._register_global_c(c)
        return c

    def _get_perms_summary(self, user_group_id):
        permissions = {
            'repositories': {},
            'repositories_groups': {},
        }
        ugroup_repo_perms = UserGroupRepoToPerm.query()\
            .options(joinedload(UserGroupRepoToPerm.permission))\
            .options(joinedload(UserGroupRepoToPerm.repository))\
            .filter(UserGroupRepoToPerm.users_group_id == user_group_id)\
            .all()

        for gr in ugroup_repo_perms:
            permissions['repositories'][gr.repository.repo_name]  \
                = gr.permission.permission_name

        ugroup_group_perms = UserGroupRepoGroupToPerm.query()\
            .options(joinedload(UserGroupRepoGroupToPerm.permission))\
            .options(joinedload(UserGroupRepoGroupToPerm.group))\
            .filter(UserGroupRepoGroupToPerm.users_group_id == user_group_id)\
            .all()

        for gr in ugroup_group_perms:
            permissions['repositories_groups'][gr.group.group_name] \
                = gr.permission.permission_name
        return permissions

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @view_config(
        route_name='user_group_members_data', request_method='GET',
        renderer='json_ext', xhr=True)
    def user_group_members(self):
        """
        Return members of given user group
        """
        user_group = self.db_user_group
        group_members_obj = sorted((x.user for x in user_group.members),
                                   key=lambda u: u.username.lower())

        group_members = [
            {
                'id': user.user_id,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'username': user.username,
                'icon_link': h.gravatar_url(user.email, 30),
                'value_display': h.person(user.email),
                'value': user.username,
                'value_type': 'user',
                'active': user.active,
            }
            for user in group_members_obj
        ]

        return {
            'members': group_members
        }

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @view_config(
        route_name='edit_user_group_perms_summary', request_method='GET',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_perms_summary(self):
        c = self.load_default_context()
        c.user_group = self.db_user_group
        c.active = 'perms_summary'
        c.permissions = self._get_perms_summary(c.user_group.users_group_id)
        return self._get_template_context(c)

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @view_config(
        route_name='edit_user_group_perms_summary_json', request_method='GET',
        renderer='json_ext')
    def user_group_perms_summary_json(self):
        self.load_default_context()
        user_group = self.db_user_group
        return self._get_perms_summary(user_group.users_group_id)

    def _revoke_perms_on_yourself(self, form_result):
        _updates = filter(lambda u: self._rhodecode_user.user_id == int(u[0]),
                          form_result['perm_updates'])
        _additions = filter(lambda u: self._rhodecode_user.user_id == int(u[0]),
                            form_result['perm_additions'])
        _deletions = filter(lambda u: self._rhodecode_user.user_id == int(u[0]),
                            form_result['perm_deletions'])
        admin_perm = 'usergroup.admin'
        if _updates   and _updates[0][1]   != admin_perm or \
           _additions and _additions[0][1] != admin_perm or \
           _deletions and _deletions[0][1] != admin_perm:
            return True
        return False

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @CSRFRequired()
    @view_config(
        route_name='user_groups_update', request_method='POST',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_update(self):
        _ = self.request.translate

        user_group = self.db_user_group
        user_group_id = user_group.users_group_id

        c = self.load_default_context()
        c.user_group = user_group
        c.group_members_obj = [x.user for x in c.user_group.members]
        c.group_members_obj.sort(key=lambda u: u.username.lower())
        c.group_members = [(x.user_id, x.username) for x in c.group_members_obj]
        c.active = 'settings'

        users_group_form = UserGroupForm(
            edit=True, old_data=c.user_group.get_dict(), allow_disabled=True)()

        old_values = c.user_group.get_api_data()
        user_group_name = self.request.POST.get('users_group_name')
        try:
            form_result = users_group_form.to_python(self.request.POST)
            pstruct = peppercorn.parse(self.request.POST.items())
            form_result['users_group_members'] = pstruct['user_group_members']

            user_group, added_members, removed_members = \
                UserGroupModel().update(c.user_group, form_result)
            updated_user_group = form_result['users_group_name']

            for user_id in added_members:
                user = User.get(user_id)
                user_data = user.get_api_data()
                audit_logger.store_web(
                    'user_group.edit.member.add',
                    action_data={'user': user_data, 'old_data': old_values},
                    user=self._rhodecode_user)

            for user_id in removed_members:
                user = User.get(user_id)
                user_data = user.get_api_data()
                audit_logger.store_web(
                    'user_group.edit.member.delete',
                    action_data={'user': user_data, 'old_data': old_values},
                    user=self._rhodecode_user)

            audit_logger.store_web(
                'user_group.edit', action_data={'old_data': old_values},
                user=self._rhodecode_user)

            h.flash(_('Updated user group %s') % updated_user_group,
                    category='success')
            Session().commit()
        except formencode.Invalid as errors:
            defaults = errors.value
            e = errors.error_dict or {}

            data = render(
                'rhodecode:templates/admin/user_groups/user_group_edit.mako',
                self._get_template_context(c), self.request)
            html = formencode.htmlfill.render(
                data,
                defaults=defaults,
                errors=e,
                prefix_error=False,
                encoding="UTF-8",
                force_defaults=False
            )
            return Response(html)

        except Exception:
            log.exception("Exception during update of user group")
            h.flash(_('Error occurred during update of user group %s')
                    % user_group_name, category='error')

        raise HTTPFound(
            h.route_path('edit_user_group', user_group_id=user_group_id))

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @CSRFRequired()
    @view_config(
        route_name='user_groups_delete', request_method='POST',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_delete(self):
        _ = self.request.translate
        user_group = self.db_user_group

        self.load_default_context()
        force = str2bool(self.request.POST.get('force'))

        old_values = user_group.get_api_data()
        try:
            UserGroupModel().delete(user_group, force=force)
            audit_logger.store_web(
                'user.delete', action_data={'old_data': old_values},
                user=self._rhodecode_user)
            Session().commit()
            h.flash(_('Successfully deleted user group'), category='success')
        except UserGroupAssignedException as e:
            h.flash(str(e), category='error')
        except Exception:
            log.exception("Exception during deletion of user group")
            h.flash(_('An error occurred during deletion of user group'),
                    category='error')
        raise HTTPFound(h.route_path('user_groups'))

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @view_config(
        route_name='edit_user_group', request_method='GET',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_edit(self):
        user_group = self.db_user_group

        c = self.load_default_context()
        c.user_group = user_group
        c.group_members_obj = [x.user for x in c.user_group.members]
        c.group_members_obj.sort(key=lambda u: u.username.lower())
        c.group_members = [(x.user_id, x.username) for x in c.group_members_obj]

        c.active = 'settings'

        defaults = user_group.get_dict()
        # fill owner
        if user_group.user:
            defaults.update({'user': user_group.user.username})
        else:
            replacement_user = User.get_first_super_admin().username
            defaults.update({'user': replacement_user})

        data = render(
            'rhodecode:templates/admin/user_groups/user_group_edit.mako',
            self._get_template_context(c), self.request)
        html = formencode.htmlfill.render(
            data,
            defaults=defaults,
            encoding="UTF-8",
            force_defaults=False
        )
        return Response(html)

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @view_config(
        route_name='edit_user_group_perms', request_method='GET',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_edit_perms(self):
        user_group = self.db_user_group
        c = self.load_default_context()
        c.user_group = user_group
        c.active = 'perms'

        defaults = {}
        # fill user group users
        for p in c.user_group.user_user_group_to_perm:
            defaults.update({'u_perm_%s' % p.user.user_id:
                             p.permission.permission_name})

        for p in c.user_group.user_group_user_group_to_perm:
            defaults.update({'g_perm_%s' % p.user_group.users_group_id:
                             p.permission.permission_name})

        data = render(
            'rhodecode:templates/admin/user_groups/user_group_edit.mako',
            self._get_template_context(c), self.request)
        html = formencode.htmlfill.render(
            data,
            defaults=defaults,
            encoding="UTF-8",
            force_defaults=False
        )
        return Response(html)

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @CSRFRequired()
    @view_config(
        route_name='edit_user_group_perms_update', request_method='POST',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_update_perms(self):
        """
        grant permission for given user group
        """
        _ = self.request.translate

        user_group = self.db_user_group
        user_group_id = user_group.users_group_id
        c = self.load_default_context()
        c.user_group = user_group
        form = UserGroupPermsForm()().to_python(self.request.POST)

        if not self._rhodecode_user.is_admin:
            if self._revoke_perms_on_yourself(form):
                msg = _('Cannot change permission for yourself as admin')
                h.flash(msg, category='warning')
                raise HTTPFound(
                    h.route_path('edit_user_group_perms',
                                 user_group_id=user_group_id))

        try:
            changes = UserGroupModel().update_permissions(
                user_group_id,
                form['perm_additions'], form['perm_updates'],
                form['perm_deletions'])

        except RepoGroupAssignmentError:
            h.flash(_('Target group cannot be the same'), category='error')
            raise HTTPFound(
                h.route_path('edit_user_group_perms',
                             user_group_id=user_group_id))

        action_data = {
            'added': changes['added'],
            'updated': changes['updated'],
            'deleted': changes['deleted'],
        }
        audit_logger.store_web(
            'user_group.edit.permissions', action_data=action_data,
            user=self._rhodecode_user)

        Session().commit()
        h.flash(_('User Group permissions updated'), category='success')
        raise HTTPFound(
            h.route_path('edit_user_group_perms', user_group_id=user_group_id))

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @view_config(
        route_name='edit_user_group_global_perms', request_method='GET',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_global_perms_edit(self):
        user_group = self.db_user_group
        c = self.load_default_context()
        c.user_group = user_group
        c.active = 'global_perms'

        c.default_user = User.get_default_user()
        defaults = c.user_group.get_dict()
        defaults.update(c.default_user.get_default_perms(suffix='_inherited'))
        defaults.update(c.user_group.get_default_perms())

        data = render(
            'rhodecode:templates/admin/user_groups/user_group_edit.mako',
            self._get_template_context(c), self.request)
        html = formencode.htmlfill.render(
            data,
            defaults=defaults,
            encoding="UTF-8",
            force_defaults=False
        )
        return Response(html)

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @CSRFRequired()
    @view_config(
        route_name='edit_user_group_global_perms_update', request_method='POST',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_global_perms_update(self):
        _ = self.request.translate
        user_group = self.db_user_group
        user_group_id = self.db_user_group.users_group_id

        c = self.load_default_context()
        c.user_group = user_group
        c.active = 'global_perms'

        try:
            # first stage that verifies the checkbox
            _form = UserIndividualPermissionsForm()
            form_result = _form.to_python(dict(self.request.POST))
            inherit_perms = form_result['inherit_default_permissions']
            user_group.inherit_default_permissions = inherit_perms
            Session().add(user_group)

            if not inherit_perms:
                # only update the individual ones if we un check the flag
                _form = UserPermissionsForm(
                    [x[0] for x in c.repo_create_choices],
                    [x[0] for x in c.repo_create_on_write_choices],
                    [x[0] for x in c.repo_group_create_choices],
                    [x[0] for x in c.user_group_create_choices],
                    [x[0] for x in c.fork_choices],
                    [x[0] for x in c.inherit_default_permission_choices])()

                form_result = _form.to_python(dict(self.request.POST))
                form_result.update(
                    {'perm_user_group_id': user_group.users_group_id})

                PermissionModel().update_user_group_permissions(form_result)

            Session().commit()
            h.flash(_('User Group global permissions updated successfully'),
                    category='success')

        except formencode.Invalid as errors:
            defaults = errors.value

            data = render(
                'rhodecode:templates/admin/user_groups/user_group_edit.mako',
                self._get_template_context(c), self.request)
            html = formencode.htmlfill.render(
                data,
                defaults=defaults,
                errors=errors.error_dict or {},
                prefix_error=False,
                encoding="UTF-8",
                force_defaults=False
            )
            return Response(html)
        except Exception:
            log.exception("Exception during permissions saving")
            h.flash(_('An error occurred during permissions saving'),
                    category='error')

        raise HTTPFound(
            h.route_path('edit_user_group_global_perms',
                         user_group_id=user_group_id))

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @view_config(
        route_name='edit_user_group_advanced', request_method='GET',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_edit_advanced(self):
        user_group = self.db_user_group

        c = self.load_default_context()
        c.user_group = user_group
        c.active = 'advanced'
        c.group_members_obj = sorted(
            (x.user for x in c.user_group.members),
            key=lambda u: u.username.lower())

        c.group_to_repos = sorted(
            (x.repository for x in c.user_group.users_group_repo_to_perm),
            key=lambda u: u.repo_name.lower())

        c.group_to_repo_groups = sorted(
            (x.group for x in c.user_group.users_group_repo_group_to_perm),
            key=lambda u: u.group_name.lower())

        c.group_to_review_rules = sorted(
            (x.users_group for x in c.user_group.user_group_review_rules),
            key=lambda u: u.users_group_name.lower())

        return self._get_template_context(c)

    @LoginRequired()
    @HasUserGroupPermissionAnyDecorator('usergroup.admin')
    @CSRFRequired()
    @view_config(
        route_name='edit_user_group_advanced_sync', request_method='POST',
        renderer='rhodecode:templates/admin/user_groups/user_group_edit.mako')
    def user_group_edit_advanced_set_synchronization(self):
        _ = self.request.translate
        user_group = self.db_user_group
        user_group_id = user_group.users_group_id

        existing = user_group.group_data.get('extern_type')

        if existing:
            new_state = user_group.group_data
            new_state['extern_type'] = None
        else:
            new_state = user_group.group_data
            new_state['extern_type'] = 'manual'
            new_state['extern_type_set_by'] = self._rhodecode_user.username

        try:
            user_group.group_data = new_state
            Session().add(user_group)
            Session().commit()

            h.flash(_('User Group synchronization updated successfully'),
                    category='success')
        except Exception:
            log.exception("Exception during sync settings saving")
            h.flash(_('An error occurred during synchronization update'),
                    category='error')

        raise HTTPFound(
            h.route_path('edit_user_group_advanced',
                         user_group_id=user_group_id))