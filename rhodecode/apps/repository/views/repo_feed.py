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

import pytz
import logging

from beaker.cache import cache_region
from pyramid.view import view_config
from pyramid.response import Response
from webhelpers.feedgenerator import Rss201rev2Feed, Atom1Feed

from rhodecode.apps._base import RepoAppView
from rhodecode.lib import audit_logger
from rhodecode.lib import helpers as h
from rhodecode.lib.auth import (LoginRequired, HasRepoPermissionAnyDecorator,
                                NotAnonymous, CSRFRequired)
from rhodecode.lib.diffs import DiffProcessor, LimitedDiffContainer
from rhodecode.lib.ext_json import json
from rhodecode.lib.utils2 import str2bool, safe_int
from rhodecode.model.db import UserApiKeys, CacheKey

log = logging.getLogger(__name__)


class RepoFeedView(RepoAppView):
    def load_default_context(self):
        c = self._get_local_tmpl_context()

        # TODO(marcink): remove repo_info and use c.rhodecode_db_repo instead
        c.repo_info = self.db_repo

        self._register_global_c(c)
        self._load_defaults()
        return c

    def _get_config(self):
        import rhodecode
        config = rhodecode.CONFIG

        return {
            'language': 'en-us',
            'feed_ttl': '5',  # TTL of feed,
            'feed_include_diff':
                str2bool(config.get('rss_include_diff', False)),
            'feed_items_per_page':
                safe_int(config.get('rss_items_per_page', 20)),
            'feed_diff_limit':
                # we need to protect from parsing huge diffs here other way
                # we can kill the server
                safe_int(config.get('rss_cut_off_limit', 32 * 1024)),
        }

    def _load_defaults(self):
        _ = self.request.translate
        config = self._get_config()
        # common values for feeds
        self.description = _('Changes on %s repository')
        self.title = self.title = _('%s %s feed') % (self.db_repo_name, '%s')
        self.language = config["language"]
        self.ttl = config["feed_ttl"]
        self.feed_include_diff = config['feed_include_diff']
        self.feed_diff_limit = config['feed_diff_limit']
        self.feed_items_per_page = config['feed_items_per_page']

    def _changes(self, commit):
        diff_processor = DiffProcessor(
            commit.diff(), diff_limit=self.feed_diff_limit)
        _parsed = diff_processor.prepare(inline_diff=False)
        limited_diff = isinstance(_parsed, LimitedDiffContainer)

        return _parsed, limited_diff

    def _get_title(self, commit):
        return h.shorter(commit.message, 160)

    def _get_description(self, commit):
        _renderer = self.request.get_partial_renderer(
            'feed/atom_feed_entry.mako')
        parsed_diff, limited_diff = self._changes(commit)
        return _renderer(
            'body',
            commit=commit,
            parsed_diff=parsed_diff,
            limited_diff=limited_diff,
            feed_include_diff=self.feed_include_diff,
        )

    def _set_timezone(self, date, tzinfo=pytz.utc):
        if not getattr(date, "tzinfo", None):
            date.replace(tzinfo=tzinfo)
        return date

    def _get_commits(self):
        return list(self.rhodecode_vcs_repo[-self.feed_items_per_page:])

    @LoginRequired(auth_token_access=[UserApiKeys.ROLE_FEED])
    @HasRepoPermissionAnyDecorator(
        'repository.read', 'repository.write', 'repository.admin')
    @view_config(
        route_name='atom_feed_home', request_method='GET',
        renderer=None)
    def atom(self):
        """
        Produce an atom-1.0 feed via feedgenerator module
        """
        self.load_default_context()

        @cache_region('long_term')
        def _generate_feed(cache_key):
            feed = Atom1Feed(
                title=self.title % self.db_repo_name,
                link=h.route_url('repo_summary', repo_name=self.db_repo_name),
                description=self.description % self.db_repo_name,
                language=self.language,
                ttl=self.ttl
            )

            for commit in reversed(self._get_commits()):
                date = self._set_timezone(commit.date)
                feed.add_item(
                    title=self._get_title(commit),
                    author_name=commit.author,
                    description=self._get_description(commit),
                    link=h.route_url(
                        'changeset_home', repo_name=self.db_repo_name,
                        revision=commit.raw_id),
                    pubdate=date,)

            return feed.mime_type, feed.writeString('utf-8')

        invalidator_context = CacheKey.repo_context_cache(
            _generate_feed, self.db_repo_name, CacheKey.CACHE_TYPE_ATOM)

        with invalidator_context as context:
            context.invalidate()
            mime_type, feed = context.compute()

        response = Response(feed)
        response.content_type = mime_type
        return response

    @LoginRequired(auth_token_access=[UserApiKeys.ROLE_FEED])
    @HasRepoPermissionAnyDecorator(
        'repository.read', 'repository.write', 'repository.admin')
    @view_config(
        route_name='rss_feed_home', request_method='GET',
        renderer=None)
    def rss(self):
        """
        Produce an rss2 feed via feedgenerator module
        """
        self.load_default_context()

        @cache_region('long_term')
        def _generate_feed(cache_key):
            feed = Rss201rev2Feed(
                title=self.title % self.db_repo_name,
                link=h.route_url('repo_summary', repo_name=self.db_repo_name),
                description=self.description % self.db_repo_name,
                language=self.language,
                ttl=self.ttl
            )

            for commit in reversed(self._get_commits()):
                date = self._set_timezone(commit.date)
                feed.add_item(
                    title=self._get_title(commit),
                    author_name=commit.author,
                    description=self._get_description(commit),
                    link=h.route_url(
                        'changeset_home', repo_name=self.db_repo_name,
                        revision=commit.raw_id),
                    pubdate=date,)

            return feed.mime_type, feed.writeString('utf-8')

        invalidator_context = CacheKey.repo_context_cache(
            _generate_feed, self.db_repo_name, CacheKey.CACHE_TYPE_RSS)

        with invalidator_context as context:
            context.invalidate()
            mime_type, feed = context.compute()

        response = Response(feed)
        response.content_type = mime_type
        return response
