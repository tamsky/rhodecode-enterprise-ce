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

import time
import logging
import operator

from pyramid.httpexceptions import HTTPFound

from rhodecode.lib import helpers as h
from rhodecode.lib.utils2 import StrictAttributeDict, safe_int, datetime_to_time
from rhodecode.lib.vcs.exceptions import RepositoryRequirementError
from rhodecode.model import repo
from rhodecode.model import repo_group
from rhodecode.model import user_group
from rhodecode.model import user
from rhodecode.model.db import User
from rhodecode.model.scm import ScmModel

log = logging.getLogger(__name__)


ADMIN_PREFIX = '/_admin'
STATIC_FILE_PREFIX = '/_static'

URL_NAME_REQUIREMENTS = {
    # group name can have a slash in them, but they must not end with a slash
    'group_name': r'.*?[^/]',
    'repo_group_name': r'.*?[^/]',
    # repo names can have a slash in them, but they must not end with a slash
    'repo_name': r'.*?[^/]',
    # file path eats up everything at the end
    'f_path': r'.*',
    # reference types
    'source_ref_type': '(branch|book|tag|rev|\%\(source_ref_type\)s)',
    'target_ref_type': '(branch|book|tag|rev|\%\(target_ref_type\)s)',
}


def add_route_with_slash(config,name, pattern, **kw):
    config.add_route(name, pattern, **kw)
    if not pattern.endswith('/'):
        config.add_route(name + '_slash', pattern + '/', **kw)


def add_route_requirements(route_path, requirements=URL_NAME_REQUIREMENTS):
    """
    Adds regex requirements to pyramid routes using a mapping dict
    e.g::
        add_route_requirements('{repo_name}/settings')
    """
    for key, regex in requirements.items():
        route_path = route_path.replace('{%s}' % key, '{%s:%s}' % (key, regex))
    return route_path


def get_format_ref_id(repo):
    """Returns a `repo` specific reference formatter function"""
    if h.is_svn(repo):
        return _format_ref_id_svn
    else:
        return _format_ref_id


def _format_ref_id(name, raw_id):
    """Default formatting of a given reference `name`"""
    return name


def _format_ref_id_svn(name, raw_id):
    """Special way of formatting a reference for Subversion including path"""
    return '%s@%s' % (name, raw_id)


class TemplateArgs(StrictAttributeDict):
    pass


class BaseAppView(object):

    def __init__(self, context, request):
        self.request = request
        self.context = context
        self.session = request.session
        self._rhodecode_user = request.user  # auth user
        self._rhodecode_db_user = self._rhodecode_user.get_instance()
        self._maybe_needs_password_change(
            request.matched_route.name, self._rhodecode_db_user)

    def _maybe_needs_password_change(self, view_name, user_obj):
        log.debug('Checking if user %s needs password change on view %s',
                  user_obj, view_name)
        skip_user_views = [
            'logout', 'login',
            'my_account_password', 'my_account_password_update'
        ]

        if not user_obj:
            return

        if user_obj.username == User.DEFAULT_USER:
            return

        now = time.time()
        should_change = user_obj.user_data.get('force_password_change')
        change_after = safe_int(should_change) or 0
        if should_change and now > change_after:
            log.debug('User %s requires password change', user_obj)
            h.flash('You are required to change your password', 'warning',
                    ignore_duplicate=True)

            if view_name not in skip_user_views:
                raise HTTPFound(
                    self.request.route_path('my_account_password'))

    def _log_creation_exception(self, e, repo_name):
        _ = self.request.translate
        reason = None
        if len(e.args) == 2:
            reason = e.args[1]

        if reason == 'INVALID_CERTIFICATE':
            log.exception(
                'Exception creating a repository: invalid certificate')
            msg = (_('Error creating repository %s: invalid certificate')
                   % repo_name)
        else:
            log.exception("Exception creating a repository")
            msg = (_('Error creating repository %s')
                   % repo_name)
        return msg

    def _get_local_tmpl_context(self, include_app_defaults=True):
        c = TemplateArgs()
        c.auth_user = self.request.user
        # TODO(marcink): migrate the usage of c.rhodecode_user to c.auth_user
        c.rhodecode_user = self.request.user

        if include_app_defaults:
            from rhodecode.lib.base import attach_context_attributes
            attach_context_attributes(c, self.request, self.request.user.user_id)

        return c

    def _register_global_c(self, tmpl_args):
        """
        Registers attributes to pylons global `c`
        """

        # TODO(marcink): remove once pyramid migration is finished
        from pylons import tmpl_context as c
        try:
            for k, v in tmpl_args.items():
                setattr(c, k, v)
        except TypeError:
            log.exception('Failed to register pylons C')
            pass

    def _get_template_context(self, tmpl_args):
        self._register_global_c(tmpl_args)

        local_tmpl_args = {
            'defaults': {},
            'errors': {},
            # register a fake 'c' to be used in templates instead of global
            # pylons c, after migration to pyramid we should rename it to 'c'
            # make sure we replace usage of _c in templates too
            '_c': tmpl_args
        }
        local_tmpl_args.update(tmpl_args)
        return local_tmpl_args

    def load_default_context(self):
        """
        example:

        def load_default_context(self):
            c = self._get_local_tmpl_context()
            c.custom_var = 'foobar'
            self._register_global_c(c)
            return c
        """
        raise NotImplementedError('Needs implementation in view class')


class RepoAppView(BaseAppView):

    def __init__(self, context, request):
        super(RepoAppView, self).__init__(context, request)
        self.db_repo = request.db_repo
        self.db_repo_name = self.db_repo.repo_name
        self.db_repo_pull_requests = ScmModel().get_pull_requests(self.db_repo)

    def _handle_missing_requirements(self, error):
        log.error(
            'Requirements are missing for repository %s: %s',
            self.db_repo_name, error.message)

    def _get_local_tmpl_context(self, include_app_defaults=False):
        _ = self.request.translate
        c = super(RepoAppView, self)._get_local_tmpl_context(
            include_app_defaults=include_app_defaults)

        # register common vars for this type of view
        c.rhodecode_db_repo = self.db_repo
        c.repo_name = self.db_repo_name
        c.repository_pull_requests = self.db_repo_pull_requests

        c.repository_requirements_missing = False
        try:
            self.rhodecode_vcs_repo = self.db_repo.scm_instance()
        except RepositoryRequirementError as e:
            c.repository_requirements_missing = True
            self._handle_missing_requirements(e)
            self.rhodecode_vcs_repo = None

        if (not c.repository_requirements_missing
            and self.rhodecode_vcs_repo is None):
            # unable to fetch this repo as vcs instance, report back to user
            h.flash(_(
                "The repository `%(repo_name)s` cannot be loaded in filesystem. "
                "Please check if it exist, or is not damaged.") %
                    {'repo_name': c.repo_name},
                    category='error', ignore_duplicate=True)
            raise HTTPFound(h.route_path('home'))

        return c

    def _get_f_path(self, matchdict, default=None):
        f_path = matchdict.get('f_path')
        if f_path:
            # fix for multiple initial slashes that causes errors for GIT
            return f_path.lstrip('/')

        return default


class RepoGroupAppView(BaseAppView):
    def __init__(self, context, request):
        super(RepoGroupAppView, self).__init__(context, request)
        self.db_repo_group = request.db_repo_group
        self.db_repo_group_name = self.db_repo_group.group_name

    def _revoke_perms_on_yourself(self, form_result):
        _updates = filter(lambda u: self._rhodecode_user.user_id == int(u[0]),
                          form_result['perm_updates'])
        _additions = filter(lambda u: self._rhodecode_user.user_id == int(u[0]),
                            form_result['perm_additions'])
        _deletions = filter(lambda u: self._rhodecode_user.user_id == int(u[0]),
                            form_result['perm_deletions'])
        admin_perm = 'group.admin'
        if _updates and _updates[0][1] != admin_perm or \
           _additions and _additions[0][1] != admin_perm or \
           _deletions and _deletions[0][1] != admin_perm:
            return True
        return False


class UserGroupAppView(BaseAppView):
    def __init__(self, context, request):
        super(UserGroupAppView, self).__init__(context, request)
        self.db_user_group = request.db_user_group
        self.db_user_group_name = self.db_user_group.users_group_name


class UserAppView(BaseAppView):
    def __init__(self, context, request):
        super(UserAppView, self).__init__(context, request)
        self.db_user = request.db_user
        self.db_user_id = self.db_user.user_id

        _ = self.request.translate
        if not request.db_user_supports_default:
            if self.db_user.username == User.DEFAULT_USER:
                h.flash(_("Editing user `{}` is disabled.".format(
                    User.DEFAULT_USER)), category='warning')
                raise HTTPFound(h.route_path('users'))


class DataGridAppView(object):
    """
    Common class to have re-usable grid rendering components
    """

    def _extract_ordering(self, request, column_map=None):
        column_map = column_map or {}
        column_index = safe_int(request.GET.get('order[0][column]'))
        order_dir = request.GET.get(
            'order[0][dir]', 'desc')
        order_by = request.GET.get(
            'columns[%s][data][sort]' % column_index, 'name_raw')

        # translate datatable to DB columns
        order_by = column_map.get(order_by) or order_by

        search_q = request.GET.get('search[value]')
        return search_q, order_by, order_dir

    def _extract_chunk(self, request):
        start = safe_int(request.GET.get('start'), 0)
        length = safe_int(request.GET.get('length'), 25)
        draw = safe_int(request.GET.get('draw'))
        return draw, start, length

    def _get_order_col(self, order_by, model):
        if isinstance(order_by, basestring):
            try:
                return operator.attrgetter(order_by)(model)
            except AttributeError:
                return None
        else:
            return order_by


class BaseReferencesView(RepoAppView):
    """
    Base for reference view for branches, tags and bookmarks.
    """
    def load_default_context(self):
        c = self._get_local_tmpl_context()

        self._register_global_c(c)
        return c

    def load_refs_context(self, ref_items, partials_template):
        _render = self.request.get_partial_renderer(partials_template)
        pre_load = ["author", "date", "message"]

        is_svn = h.is_svn(self.rhodecode_vcs_repo)
        is_hg = h.is_hg(self.rhodecode_vcs_repo)

        format_ref_id = get_format_ref_id(self.rhodecode_vcs_repo)

        closed_refs = {}
        if is_hg:
            closed_refs = self.rhodecode_vcs_repo.branches_closed

        data = []
        for ref_name, commit_id in ref_items:
            commit = self.rhodecode_vcs_repo.get_commit(
                commit_id=commit_id, pre_load=pre_load)
            closed = ref_name in closed_refs

            # TODO: johbo: Unify generation of reference links
            use_commit_id = '/' in ref_name or is_svn

            if use_commit_id:
                files_url = h.route_path(
                    'repo_files',
                    repo_name=self.db_repo_name,
                    f_path=ref_name if is_svn else '',
                    commit_id=commit_id)

            else:
                files_url = h.route_path(
                    'repo_files',
                    repo_name=self.db_repo_name,
                    f_path=ref_name if is_svn else '',
                    commit_id=ref_name,
                    _query=dict(at=ref_name))

            data.append({
                "name": _render('name', ref_name, files_url, closed),
                "name_raw": ref_name,
                "date": _render('date', commit.date),
                "date_raw": datetime_to_time(commit.date),
                "author": _render('author', commit.author),
                "commit": _render(
                    'commit', commit.message, commit.raw_id, commit.idx),
                "commit_raw": commit.idx,
                "compare": _render(
                    'compare', format_ref_id(ref_name, commit.raw_id)),
            })

        return data


class RepoRoutePredicate(object):
    def __init__(self, val, config):
        self.val = val

    def text(self):
        return 'repo_route = %s' % self.val

    phash = text

    def __call__(self, info, request):

        if hasattr(request, 'vcs_call'):
            # skip vcs calls
            return

        repo_name = info['match']['repo_name']
        repo_model = repo.RepoModel()
        by_name_match = repo_model.get_by_repo_name(repo_name, cache=True)

        def redirect_if_creating(db_repo):
            if db_repo.repo_state in [repo.Repository.STATE_PENDING]:
                raise HTTPFound(
                    request.route_path('repo_creating',
                                       repo_name=db_repo.repo_name))

        if by_name_match:
            # register this as request object we can re-use later
            request.db_repo = by_name_match
            redirect_if_creating(by_name_match)
            return True

        by_id_match = repo_model.get_repo_by_id(repo_name)
        if by_id_match:
            request.db_repo = by_id_match
            redirect_if_creating(by_id_match)
            return True

        return False


class RepoTypeRoutePredicate(object):
    def __init__(self, val, config):
        self.val = val or ['hg', 'git', 'svn']

    def text(self):
        return 'repo_accepted_type = %s' % self.val

    phash = text

    def __call__(self, info, request):
        if hasattr(request, 'vcs_call'):
            # skip vcs calls
            return

        rhodecode_db_repo = request.db_repo

        log.debug(
            '%s checking repo type for %s in %s',
            self.__class__.__name__, rhodecode_db_repo.repo_type, self.val)

        if rhodecode_db_repo.repo_type in self.val:
            return True
        else:
            log.warning('Current view is not supported for repo type:%s',
                        rhodecode_db_repo.repo_type)
            #
            # h.flash(h.literal(
            #     _('Action not supported for %s.' % rhodecode_repo.alias)),
            #     category='warning')
            # return redirect(
            #     route_path('repo_summary', repo_name=cls.rhodecode_db_repo.repo_name))

            return False


class RepoGroupRoutePredicate(object):
    def __init__(self, val, config):
        self.val = val

    def text(self):
        return 'repo_group_route = %s' % self.val

    phash = text

    def __call__(self, info, request):
        if hasattr(request, 'vcs_call'):
            # skip vcs calls
            return

        repo_group_name = info['match']['repo_group_name']
        repo_group_model = repo_group.RepoGroupModel()
        by_name_match = repo_group_model.get_by_group_name(
            repo_group_name, cache=True)

        if by_name_match:
            # register this as request object we can re-use later
            request.db_repo_group = by_name_match
            return True

        return False


class UserGroupRoutePredicate(object):
    def __init__(self, val, config):
        self.val = val

    def text(self):
        return 'user_group_route = %s' % self.val

    phash = text

    def __call__(self, info, request):
        if hasattr(request, 'vcs_call'):
            # skip vcs calls
            return

        user_group_id = info['match']['user_group_id']
        user_group_model = user_group.UserGroup()
        by_id_match = user_group_model.get(
            user_group_id, cache=True)

        if by_id_match:
            # register this as request object we can re-use later
            request.db_user_group = by_id_match
            return True

        return False


class UserRoutePredicateBase(object):
    supports_default = None

    def __init__(self, val, config):
        self.val = val

    def text(self):
        raise NotImplementedError()

    def __call__(self, info, request):
        if hasattr(request, 'vcs_call'):
            # skip vcs calls
            return

        user_id = info['match']['user_id']
        user_model = user.User()
        by_id_match = user_model.get(
            user_id, cache=True)

        if by_id_match:
            # register this as request object we can re-use later
            request.db_user = by_id_match
            request.db_user_supports_default = self.supports_default
            return True

        return False


class UserRoutePredicate(UserRoutePredicateBase):
    supports_default = False

    def text(self):
        return 'user_route = %s' % self.val

    phash = text


class UserRouteWithDefaultPredicate(UserRoutePredicateBase):
    supports_default = True

    def text(self):
        return 'user_with_default_route = %s' % self.val

    phash = text


def includeme(config):
    config.add_route_predicate(
        'repo_route', RepoRoutePredicate)
    config.add_route_predicate(
        'repo_accepted_types', RepoTypeRoutePredicate)
    config.add_route_predicate(
        'repo_group_route', RepoGroupRoutePredicate)
    config.add_route_predicate(
        'user_group_route', UserGroupRoutePredicate)
    config.add_route_predicate(
        'user_route_with_default', UserRouteWithDefaultPredicate)
    config.add_route_predicate(
        'user_route', UserRoutePredicate)