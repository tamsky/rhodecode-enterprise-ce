# Copyright (C) 2016-2016  RhodeCode GmbH
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

from rhodecode.translation import lazy_ugettext
from rhodecode.model.db import User, Repository, Session
from rhodecode.events.base import RhodecodeEvent
from rhodecode.lib.vcs.exceptions import CommitDoesNotExistError

log = logging.getLogger(__name__)

def _commits_as_dict(commit_ids, repos):
    """
    Helper function to serialize commit_ids

    :param commit_ids: commits to get
    :param repos: list of repos to check
    """
    from rhodecode.lib.utils2 import extract_mentioned_users
    from rhodecode.model.db import Repository
    from rhodecode.lib import helpers as h
    from rhodecode.lib.helpers import process_patterns
    from rhodecode.lib.helpers import urlify_commit_message

    if not repos:
        raise Exception('no repo defined')

    if not isinstance(repos, (tuple, list)):
        repos = [repos]

    if not commit_ids:
        return []

    needed_commits = list(commit_ids)

    commits = []
    reviewers = []
    for repo in repos:
        if not needed_commits:
            return commits # return early if we have the commits we need

        vcs_repo = repo.scm_instance(cache=False)
        try:
            # use copy of needed_commits since we modify it while iterating
            for commit_id in list(needed_commits):
                try:
                    cs = vcs_repo.get_changeset(commit_id)
                except CommitDoesNotExistError:
                    continue # maybe its in next repo

                cs_data = cs.__json__()
                cs_data['mentions'] = extract_mentioned_users(cs_data['message'])
                cs_data['reviewers'] = reviewers
                cs_data['url'] = h.url('changeset_home',
                    repo_name=repo.repo_name,
                    revision=cs_data['raw_id'],
                    qualified=True
                )
                urlified_message, issues_data = process_patterns(
                    cs_data['message'], repo.repo_name)
                cs_data['issues'] = issues_data
                cs_data['message_html'] = urlify_commit_message(cs_data['message'],
                    repo.repo_name)
                commits.append(cs_data)

                needed_commits.remove(commit_id)

        except Exception as e:
            log.exception(e)
            # we don't send any commits when crash happens, only full list matters
            # we short circuit then.
            return []

    missing_commits = set(commit_ids) - set(c['raw_id'] for c in commits)
    if missing_commits:
        log.error('missing commits: %s' % ', '.join(missing_commits))

    return commits


def _issues_as_dict(commits):
    """ Helper function to serialize issues from commits """
    issues = {}
    for commit in commits:
        for issue in commit['issues']:
            issues[issue['id']] = issue
    return issues

class RepoEvent(RhodecodeEvent):
    """
    Base class for events acting on a repository.

    :param repo: a :class:`Repository` instance
    """

    def __init__(self, repo):
        super(RepoEvent, self).__init__()
        self.repo = repo

    def as_dict(self):
        from rhodecode.model.repo import RepoModel
        data = super(RepoEvent, self).as_dict()
        data.update({
            'repo': {
                'repo_id': self.repo.repo_id,
                'repo_name': self.repo.repo_name,
                'repo_type': self.repo.repo_type,
                'url': RepoModel().get_url(self.repo)
            }
        })
        return data


class RepoPreCreateEvent(RepoEvent):
    """
    An instance of this class is emitted as an :term:`event` before a repo is
    created.
    """
    name = 'repo-pre-create'
    display_name = lazy_ugettext('repository pre create')


class RepoCreateEvent(RepoEvent):
    """
    An instance of this class is emitted as an :term:`event` whenever a repo is
    created.
    """
    name = 'repo-create'
    display_name = lazy_ugettext('repository created')


class RepoPreDeleteEvent(RepoEvent):
    """
    An instance of this class is emitted as an :term:`event` whenever a repo is
    created.
    """
    name = 'repo-pre-delete'
    display_name = lazy_ugettext('repository pre delete')


class RepoDeleteEvent(RepoEvent):
    """
    An instance of this class is emitted as an :term:`event` whenever a repo is
    created.
    """
    name = 'repo-delete'
    display_name = lazy_ugettext('repository deleted')


class RepoVCSEvent(RepoEvent):
    """
    Base class for events triggered by the VCS
    """
    def __init__(self, repo_name, extras):
        self.repo = Repository.get_by_repo_name(repo_name)
        if not self.repo:
            raise Exception('repo by this name %s does not exist' % repo_name)
        self.extras = extras
        super(RepoVCSEvent, self).__init__(self.repo)

    @property
    def actor(self):
        if self.extras.get('username'):
            return User.get_by_username(self.extras['username'])

    @property
    def actor_ip(self):
        if self.extras.get('ip'):
            return self.extras['ip']

    @property
    def server_url(self):
        if self.extras.get('server_url'):
            return self.extras['server_url']


class RepoPrePullEvent(RepoVCSEvent):
    """
    An instance of this class is emitted as an :term:`event` before commits
    are pulled from a repo.
    """
    name = 'repo-pre-pull'
    display_name = lazy_ugettext('repository pre pull')


class RepoPullEvent(RepoVCSEvent):
    """
    An instance of this class is emitted as an :term:`event` after commits
    are pulled from a repo.
    """
    name = 'repo-pull'
    display_name = lazy_ugettext('repository pull')


class RepoPrePushEvent(RepoVCSEvent):
    """
    An instance of this class is emitted as an :term:`event` before commits
    are pushed to a repo.
    """
    name = 'repo-pre-push'
    display_name = lazy_ugettext('repository pre push')


class RepoPushEvent(RepoVCSEvent):
    """
    An instance of this class is emitted as an :term:`event` after commits
    are pushed to a repo.

    :param extras: (optional) dict of data from proxied VCS actions
    """
    name = 'repo-push'
    display_name = lazy_ugettext('repository push')

    def __init__(self, repo_name, pushed_commit_ids, extras):
        super(RepoPushEvent, self).__init__(repo_name, extras)
        self.pushed_commit_ids = pushed_commit_ids

    def as_dict(self):
        data = super(RepoPushEvent, self).as_dict()
        branch_url = repo_url = data['repo']['url']

        commits = _commits_as_dict(
            commit_ids=self.pushed_commit_ids, repos=[self.repo])

        last_branch = None
        for commit in reversed(commits):
            commit['branch'] = commit['branch'] or last_branch
            last_branch = commit['branch']
        issues = _issues_as_dict(commits)

        branches = set(
            commit['branch'] for commit in commits if commit['branch'])
        branches = [
            {
                'name': branch,
                'url': '{}/changelog?branch={}'.format(
                    data['repo']['url'], branch)
            }
            for branch in branches
        ]

        data['push'] = {
            'commits': commits,
            'issues': issues,
            'branches': branches,
        }
        return data
