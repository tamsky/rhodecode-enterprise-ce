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
import string

from pyramid.view import view_config

from beaker.cache import cache_region


from rhodecode.controllers import utils

from rhodecode.apps._base import RepoAppView
from rhodecode.config.conf import (LANGUAGES_EXTENSIONS_MAP)
from rhodecode.lib import caches, helpers as h
from rhodecode.lib.helpers import RepoPage
from rhodecode.lib.utils2 import safe_str, safe_int
from rhodecode.lib.auth import LoginRequired, HasRepoPermissionAnyDecorator
from rhodecode.lib.markup_renderer import MarkupRenderer, relative_links
from rhodecode.lib.ext_json import json
from rhodecode.lib.vcs.backends.base import EmptyCommit
from rhodecode.lib.vcs.exceptions import CommitError, EmptyRepositoryError
from rhodecode.model.db import Statistics, CacheKey, User
from rhodecode.model.meta import Session
from rhodecode.model.repo import ReadmeFinder
from rhodecode.model.scm import ScmModel

log = logging.getLogger(__name__)


class RepoSummaryView(RepoAppView):

    def load_default_context(self):
        c = self._get_local_tmpl_context(include_app_defaults=True)

        # TODO(marcink): remove repo_info and use c.rhodecode_db_repo instead
        c.repo_info = self.db_repo
        c.rhodecode_repo = None
        if not c.repository_requirements_missing:
            c.rhodecode_repo = self.rhodecode_vcs_repo

        self._register_global_c(c)
        return c

    def _get_readme_data(self, db_repo, default_renderer):
        repo_name = db_repo.repo_name
        log.debug('Looking for README file')

        @cache_region('long_term')
        def _generate_readme(cache_key):
            readme_data = None
            readme_node = None
            readme_filename = None
            commit = self._get_landing_commit_or_none(db_repo)
            if commit:
                log.debug("Searching for a README file.")
                readme_node = ReadmeFinder(default_renderer).search(commit)
            if readme_node:
                relative_url = h.url('files_raw_home',
                                     repo_name=repo_name,
                                     revision=commit.raw_id,
                                     f_path=readme_node.path)
                readme_data = self._render_readme_or_none(
                    commit, readme_node, relative_url)
                readme_filename = readme_node.path
            return readme_data, readme_filename

        invalidator_context = CacheKey.repo_context_cache(
            _generate_readme, repo_name, CacheKey.CACHE_TYPE_README)

        with invalidator_context as context:
            context.invalidate()
            computed = context.compute()

        return computed

    def _get_landing_commit_or_none(self, db_repo):
        log.debug("Getting the landing commit.")
        try:
            commit = db_repo.get_landing_commit()
            if not isinstance(commit, EmptyCommit):
                return commit
            else:
                log.debug("Repository is empty, no README to render.")
        except CommitError:
            log.exception(
                "Problem getting commit when trying to render the README.")

    def _render_readme_or_none(self, commit, readme_node, relative_url):
        log.debug(
            'Found README file `%s` rendering...', readme_node.path)
        renderer = MarkupRenderer()
        try:
            html_source = renderer.render(
                readme_node.content, filename=readme_node.path)
            if relative_url:
                return relative_links(html_source, relative_url)
            return html_source
        except Exception:
            log.exception(
                "Exception while trying to render the README")

    def _load_commits_context(self, c):
        p = safe_int(self.request.GET.get('page'), 1)
        size = safe_int(self.request.GET.get('size'), 10)

        def url_generator(**kw):
            query_params = {
                'size': size
            }
            query_params.update(kw)
            return h.route_path(
                'repo_summary_commits',
                repo_name=c.rhodecode_db_repo.repo_name, _query=query_params)

        pre_load = ['author', 'branch', 'date', 'message']
        try:
            collection = self.rhodecode_vcs_repo.get_commits(pre_load=pre_load)
        except EmptyRepositoryError:
            collection = self.rhodecode_vcs_repo

        c.repo_commits = RepoPage(
            collection, page=p, items_per_page=size, url=url_generator)
        page_ids = [x.raw_id for x in c.repo_commits]
        c.comments = self.db_repo.get_comments(page_ids)
        c.statuses = self.db_repo.statuses(page_ids)

    @LoginRequired()
    @HasRepoPermissionAnyDecorator(
        'repository.read', 'repository.write', 'repository.admin')
    @view_config(
        route_name='repo_summary_commits', request_method='GET',
        renderer='rhodecode:templates/summary/summary_commits.mako')
    def summary_commits(self):
        c = self.load_default_context()
        self._load_commits_context(c)
        return self._get_template_context(c)

    @LoginRequired()
    @HasRepoPermissionAnyDecorator(
        'repository.read', 'repository.write', 'repository.admin')
    @view_config(
        route_name='repo_summary', request_method='GET',
        renderer='rhodecode:templates/summary/summary.mako')
    @view_config(
        route_name='repo_summary_slash', request_method='GET',
        renderer='rhodecode:templates/summary/summary.mako')
    def summary(self):
        c = self.load_default_context()

        # Prepare the clone URL
        username = ''
        if self._rhodecode_user.username != User.DEFAULT_USER:
            username = safe_str(self._rhodecode_user.username)

        _def_clone_uri = _def_clone_uri_by_id = c.clone_uri_tmpl
        if '{repo}' in _def_clone_uri:
            _def_clone_uri_by_id = _def_clone_uri.replace(
                '{repo}', '_{repoid}')
        elif '{repoid}' in _def_clone_uri:
            _def_clone_uri_by_id = _def_clone_uri.replace(
                '_{repoid}', '{repo}')

        c.clone_repo_url = self.db_repo.clone_url(
            user=username, uri_tmpl=_def_clone_uri)
        c.clone_repo_url_id = self.db_repo.clone_url(
            user=username, uri_tmpl=_def_clone_uri_by_id)

        # If enabled, get statistics data

        c.show_stats = bool(self.db_repo.enable_statistics)

        stats = Session().query(Statistics) \
            .filter(Statistics.repository == self.db_repo) \
            .scalar()

        c.stats_percentage = 0

        if stats and stats.languages:
            c.no_data = False is self.db_repo.enable_statistics
            lang_stats_d = json.loads(stats.languages)

            # Sort first by decreasing count and second by the file extension,
            # so we have a consistent output.
            lang_stats_items = sorted(lang_stats_d.iteritems(),
                                      key=lambda k: (-k[1], k[0]))[:10]
            lang_stats = [(x, {"count": y,
                               "desc": LANGUAGES_EXTENSIONS_MAP.get(x)})
                          for x, y in lang_stats_items]

            c.trending_languages = json.dumps(lang_stats)
        else:
            c.no_data = True
            c.trending_languages = json.dumps({})

        scm_model = ScmModel()
        c.enable_downloads = self.db_repo.enable_downloads
        c.repository_followers = scm_model.get_followers(self.db_repo)
        c.repository_forks = scm_model.get_forks(self.db_repo)
        c.repository_is_user_following = scm_model.is_following_repo(
            self.db_repo_name, self._rhodecode_user.user_id)

        # first interaction with the VCS instance after here...
        if c.repository_requirements_missing:
            self.request.override_renderer = \
                'rhodecode:templates/summary/missing_requirements.mako'
            return self._get_template_context(c)

        c.readme_data, c.readme_file = \
            self._get_readme_data(self.db_repo, c.visual.default_renderer)

        # loads the summary commits template context
        self._load_commits_context(c)

        return self._get_template_context(c)

    def get_request_commit_id(self):
        return self.request.matchdict['commit_id']

    @LoginRequired()
    @HasRepoPermissionAnyDecorator(
        'repository.read', 'repository.write', 'repository.admin')
    @view_config(
        route_name='repo_stats', request_method='GET',
        renderer='json_ext')
    def repo_stats(self):
        commit_id = self.get_request_commit_id()

        _namespace = caches.get_repo_namespace_key(
            caches.SUMMARY_STATS, self.db_repo_name)
        show_stats = bool(self.db_repo.enable_statistics)
        cache_manager = caches.get_cache_manager(
            'repo_cache_long', _namespace)
        _cache_key = caches.compute_key_from_params(
            self.db_repo_name, commit_id, show_stats)

        def compute_stats():
            code_stats = {}
            size = 0
            try:
                scm_instance = self.db_repo.scm_instance()
                commit = scm_instance.get_commit(commit_id)

                for node in commit.get_filenodes_generator():
                    size += node.size
                    if not show_stats:
                        continue
                    ext = string.lower(node.extension)
                    ext_info = LANGUAGES_EXTENSIONS_MAP.get(ext)
                    if ext_info:
                        if ext in code_stats:
                            code_stats[ext]['count'] += 1
                        else:
                            code_stats[ext] = {"count": 1, "desc": ext_info}
            except EmptyRepositoryError:
                pass
            return {'size': h.format_byte_size_binary(size),
                    'code_stats': code_stats}

        stats = cache_manager.get(_cache_key, createfunc=compute_stats)
        return stats

    @LoginRequired()
    @HasRepoPermissionAnyDecorator(
        'repository.read', 'repository.write', 'repository.admin')
    @view_config(
        route_name='repo_refs_data', request_method='GET',
        renderer='json_ext')
    def repo_refs_data(self):
        _ = self.request.translate
        self.load_default_context()

        repo = self.rhodecode_vcs_repo
        refs_to_create = [
            (_("Branch"), repo.branches, 'branch'),
            (_("Tag"), repo.tags, 'tag'),
            (_("Bookmark"), repo.bookmarks, 'book'),
        ]
        res = self._create_reference_data(
            repo, self.db_repo_name, refs_to_create)
        data = {
            'more': False,
            'results': res
        }
        return data

    @LoginRequired()
    @HasRepoPermissionAnyDecorator(
        'repository.read', 'repository.write', 'repository.admin')
    @view_config(
        route_name='repo_refs_changelog_data', request_method='GET',
        renderer='json_ext')
    def repo_refs_changelog_data(self):
        _ = self.request.translate
        self.load_default_context()

        repo = self.rhodecode_vcs_repo

        refs_to_create = [
            (_("Branches"), repo.branches, 'branch'),
            (_("Closed branches"), repo.branches_closed, 'branch_closed'),
            # TODO: enable when vcs can handle bookmarks filters
            # (_("Bookmarks"), repo.bookmarks, "book"),
        ]
        res = self._create_reference_data(
            repo, self.db_repo_name, refs_to_create)
        data = {
            'more': False,
            'results': res
        }
        return data

    def _create_reference_data(self, repo, full_repo_name, refs_to_create):
        format_ref_id = utils.get_format_ref_id(repo)

        result = []
        for title, refs, ref_type in refs_to_create:
            if refs:
                result.append({
                    'text': title,
                    'children': self._create_reference_items(
                        repo, full_repo_name, refs, ref_type,
                        format_ref_id),
                })
        return result

    def _create_reference_items(self, repo, full_repo_name, refs, ref_type,
                                format_ref_id):
        result = []
        is_svn = h.is_svn(repo)
        for ref_name, raw_id in refs.iteritems():
            files_url = self._create_files_url(
                repo, full_repo_name, ref_name, raw_id, is_svn)
            result.append({
                'text': ref_name,
                'id': format_ref_id(ref_name, raw_id),
                'raw_id': raw_id,
                'type': ref_type,
                'files_url': files_url,
            })
        return result

    def _create_files_url(self, repo, full_repo_name, ref_name, raw_id, is_svn):
        use_commit_id = '/' in ref_name or is_svn
        return h.url(
            'files_home',
            repo_name=full_repo_name,
            f_path=ref_name if is_svn else '',
            revision=raw_id if use_commit_id else ref_name,
            at=ref_name)