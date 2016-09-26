# -*- coding: utf-8 -*-

# Copyright (C) 2013-2016  RhodeCode GmbH
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


"""
gist controller for RhodeCode
"""

import time
import logging

import formencode
import peppercorn
from formencode import htmlfill

from pylons import request, response, tmpl_context as c, url
from pylons.controllers.util import abort, redirect
from pylons.i18n.translation import _
from webob.exc import HTTPNotFound, HTTPForbidden
from sqlalchemy.sql.expression import or_


from rhodecode.model.gist import GistModel
from rhodecode.model.meta import Session
from rhodecode.model.db import Gist, User
from rhodecode.lib import auth
from rhodecode.lib import helpers as h
from rhodecode.lib.base import BaseController, render
from rhodecode.lib.auth import LoginRequired, NotAnonymous
from rhodecode.lib.utils import jsonify
from rhodecode.lib.utils2 import safe_str, safe_int, time_to_datetime
from rhodecode.lib.ext_json import json
from rhodecode.lib.vcs.exceptions import VCSError, NodeNotChangedError
from rhodecode.model import validation_schema
from rhodecode.model.validation_schema.schemas import gist_schema


log = logging.getLogger(__name__)


class GistsController(BaseController):
    """REST Controller styled on the Atom Publishing Protocol"""

    def __load_defaults(self, extra_values=None):
        c.lifetime_values = [
            (-1, _('forever')),
            (5, _('5 minutes')),
            (60, _('1 hour')),
            (60 * 24, _('1 day')),
            (60 * 24 * 30, _('1 month')),
        ]
        if extra_values:
            c.lifetime_values.append(extra_values)
        c.lifetime_options = [(c.lifetime_values, _("Lifetime"))]
        c.acl_options = [
            (Gist.ACL_LEVEL_PRIVATE, _("Requires registered account")),
            (Gist.ACL_LEVEL_PUBLIC, _("Can be accessed by anonymous users"))
        ]

    @LoginRequired()
    def index(self):
        """GET /admin/gists: All items in the collection"""
        # url('gists')
        not_default_user = c.rhodecode_user.username != User.DEFAULT_USER
        c.show_private = request.GET.get('private') and not_default_user
        c.show_public = request.GET.get('public') and not_default_user
        c.show_all = request.GET.get('all') and c.rhodecode_user.admin

        gists = _gists = Gist().query()\
            .filter(or_(Gist.gist_expires == -1, Gist.gist_expires >= time.time()))\
            .order_by(Gist.created_on.desc())

        c.active = 'public'
        # MY private
        if c.show_private and not c.show_public:
            gists = _gists.filter(Gist.gist_type == Gist.GIST_PRIVATE)\
                        .filter(Gist.gist_owner == c.rhodecode_user.user_id)
            c.active = 'my_private'
        # MY public
        elif c.show_public and not c.show_private:
            gists = _gists.filter(Gist.gist_type == Gist.GIST_PUBLIC)\
                        .filter(Gist.gist_owner == c.rhodecode_user.user_id)
            c.active = 'my_public'
        # MY public+private
        elif c.show_private and c.show_public:
            gists = _gists.filter(or_(Gist.gist_type == Gist.GIST_PUBLIC,
                                      Gist.gist_type == Gist.GIST_PRIVATE))\
                        .filter(Gist.gist_owner == c.rhodecode_user.user_id)
            c.active = 'my_all'
        # Show all by super-admin
        elif c.show_all:
            c.active = 'all'
            gists = _gists

        # default show ALL public gists
        if not c.show_public and not c.show_private and not c.show_all:
            gists = _gists.filter(Gist.gist_type == Gist.GIST_PUBLIC)
            c.active = 'public'

        from rhodecode.lib.utils import PartialRenderer
        _render = PartialRenderer('data_table/_dt_elements.html')

        data = []

        for gist in gists:
            data.append({
                'created_on': _render('gist_created', gist.created_on),
                'created_on_raw': gist.created_on,
                'type': _render('gist_type', gist.gist_type),
                'access_id': _render('gist_access_id', gist.gist_access_id, gist.owner.full_contact),
                'author': _render('gist_author', gist.owner.full_contact, gist.created_on, gist.gist_expires),
                'author_raw': h.escape(gist.owner.full_contact),
                'expires': _render('gist_expires', gist.gist_expires),
                'description': _render('gist_description', gist.gist_description)
            })
        c.data = json.dumps(data)
        return render('admin/gists/index.html')

    @LoginRequired()
    @NotAnonymous()
    @auth.CSRFRequired()
    def create(self):
        """POST /admin/gists: Create a new item"""
        # url('gists')
        self.__load_defaults()

        data = dict(request.POST)
        data['filename'] = data.get('filename') or Gist.DEFAULT_FILENAME
        data['nodes'] = [{
            'filename': data['filename'],
            'content': data.get('content'),
            'mimetype': data.get('mimetype')  # None is autodetect
        }]

        data['gist_type'] = (
            Gist.GIST_PUBLIC if data.get('public') else Gist.GIST_PRIVATE)
        data['gist_acl_level'] = (
            data.get('gist_acl_level') or Gist.ACL_LEVEL_PRIVATE)

        schema = gist_schema.GistSchema().bind(
            lifetime_options=[x[0] for x in c.lifetime_values])

        try:

            schema_data = schema.deserialize(data)
            # convert to safer format with just KEYs so we sure no duplicates
            schema_data['nodes'] = gist_schema.sequence_to_nodes(
                schema_data['nodes'])

            gist = GistModel().create(
                gist_id=schema_data['gistid'],  # custom access id not real ID
                description=schema_data['description'],
                owner=c.rhodecode_user.user_id,
                gist_mapping=schema_data['nodes'],
                gist_type=schema_data['gist_type'],
                lifetime=schema_data['lifetime'],
                gist_acl_level=schema_data['gist_acl_level']
            )
            Session().commit()
            new_gist_id = gist.gist_access_id
        except validation_schema.Invalid as errors:
            defaults = data
            errors = errors.asdict()

            if 'nodes.0.content' in errors:
                errors['content'] = errors['nodes.0.content']
                del errors['nodes.0.content']
            if 'nodes.0.filename' in errors:
                errors['filename'] = errors['nodes.0.filename']
                del errors['nodes.0.filename']

            return formencode.htmlfill.render(
                render('admin/gists/new.html'),
                defaults=defaults,
                errors=errors,
                prefix_error=False,
                encoding="UTF-8",
                force_defaults=False
            )

        except Exception:
            log.exception("Exception while trying to create a gist")
            h.flash(_('Error occurred during gist creation'), category='error')
            return redirect(url('new_gist'))
        return redirect(url('gist', gist_id=new_gist_id))

    @LoginRequired()
    @NotAnonymous()
    def new(self, format='html'):
        """GET /admin/gists/new: Form to create a new item"""
        # url('new_gist')
        self.__load_defaults()
        return render('admin/gists/new.html')

    @LoginRequired()
    @NotAnonymous()
    @auth.CSRFRequired()
    def delete(self, gist_id):
        """DELETE /admin/gists/gist_id: Delete an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="DELETE" />
        # Or using helpers:
        #    h.form(url('gist', gist_id=ID),
        #           method='delete')
        # url('gist', gist_id=ID)
        c.gist = Gist.get_or_404(gist_id)

        owner = c.gist.gist_owner == c.rhodecode_user.user_id
        if not (h.HasPermissionAny('hg.admin')() or owner):
            raise HTTPForbidden()

        GistModel().delete(c.gist)
        Session().commit()
        h.flash(_('Deleted gist %s') % c.gist.gist_access_id, category='success')

        return redirect(url('gists'))

    def _add_gist_to_context(self, gist_id):
        c.gist = Gist.get_or_404(gist_id)

        # Check if this gist is expired
        if c.gist.gist_expires != -1:
            if time.time() > c.gist.gist_expires:
                log.error(
                    'Gist expired at %s', time_to_datetime(c.gist.gist_expires))
                raise HTTPNotFound()

        # check if this gist requires a login
        is_default_user = c.rhodecode_user.username == User.DEFAULT_USER
        if c.gist.acl_level == Gist.ACL_LEVEL_PRIVATE and is_default_user:
            log.error("Anonymous user %s tried to access protected gist `%s`",
                      c.rhodecode_user, gist_id)
            raise HTTPNotFound()

    @LoginRequired()
    def show(self, gist_id, revision='tip', format='html', f_path=None):
        """GET /admin/gists/gist_id: Show a specific item"""
        # url('gist', gist_id=ID)
        self._add_gist_to_context(gist_id)
        c.render = not request.GET.get('no-render', False)

        try:
            c.file_last_commit, c.files = GistModel().get_gist_files(
                gist_id, revision=revision)
        except VCSError:
            log.exception("Exception in gist show")
            raise HTTPNotFound()
        if format == 'raw':
            content = '\n\n'.join([f.content for f in c.files
                                   if (f_path is None or f.path == f_path)])
            response.content_type = 'text/plain'
            return content
        return render('admin/gists/show.html')

    @LoginRequired()
    @NotAnonymous()
    @auth.CSRFRequired()
    def edit(self, gist_id):
        self.__load_defaults()
        self._add_gist_to_context(gist_id)

        owner = c.gist.gist_owner == c.rhodecode_user.user_id
        if not (h.HasPermissionAny('hg.admin')() or owner):
            raise HTTPForbidden()

        data = peppercorn.parse(request.POST.items())

        schema = gist_schema.GistSchema()
        schema = schema.bind(
            # '0' is special value to leave lifetime untouched
            lifetime_options=[x[0] for x in c.lifetime_values] + [0],
        )

        try:
            schema_data = schema.deserialize(data)
            # convert to safer format with just KEYs so we sure no duplicates
            schema_data['nodes'] = gist_schema.sequence_to_nodes(
                schema_data['nodes'])

            GistModel().update(
                gist=c.gist,
                description=schema_data['description'],
                owner=c.gist.owner,
                gist_mapping=schema_data['nodes'],
                lifetime=schema_data['lifetime'],
                gist_acl_level=schema_data['gist_acl_level']
            )

            Session().commit()
            h.flash(_('Successfully updated gist content'), category='success')
        except NodeNotChangedError:
            # raised if nothing was changed in repo itself. We anyway then
            # store only DB stuff for gist
            Session().commit()
            h.flash(_('Successfully updated gist data'), category='success')
        except validation_schema.Invalid as errors:
            errors = errors.asdict()
            h.flash(_('Error occurred during update of gist {}: {}').format(
                gist_id, errors), category='error')
        except Exception:
            log.exception("Exception in gist edit")
            h.flash(_('Error occurred during update of gist %s') % gist_id,
                    category='error')

        return redirect(url('gist', gist_id=gist_id))

    @LoginRequired()
    @NotAnonymous()
    def edit_form(self, gist_id, format='html'):
        """GET /admin/gists/gist_id/edit: Form to edit an existing item"""
        # url('edit_gist', gist_id=ID)
        self._add_gist_to_context(gist_id)

        owner = c.gist.gist_owner == c.rhodecode_user.user_id
        if not (h.HasPermissionAny('hg.admin')() or owner):
            raise HTTPForbidden()

        try:
            c.file_last_commit, c.files = GistModel().get_gist_files(gist_id)
        except VCSError:
            log.exception("Exception in gist edit")
            raise HTTPNotFound()

        if c.gist.gist_expires == -1:
            expiry = _('never')
        else:
            # this cannot use timeago, since it's used in select2 as a value
            expiry = h.age(h.time_to_datetime(c.gist.gist_expires))
        self.__load_defaults(
            extra_values=(0, _('%(expiry)s - current value') % {'expiry': expiry}))
        return render('admin/gists/edit.html')

    @LoginRequired()
    @NotAnonymous()
    @jsonify
    def check_revision(self, gist_id):
        c.gist = Gist.get_or_404(gist_id)
        last_rev = c.gist.scm_instance().get_commit()
        success = True
        revision = request.GET.get('revision')

        ##TODO: maybe move this to model ?
        if revision != last_rev.raw_id:
            log.error('Last revision %s is different then submitted %s'
                      % (revision, last_rev))
            # our gist has newer version than we
            success = False

        return {'success': success}
