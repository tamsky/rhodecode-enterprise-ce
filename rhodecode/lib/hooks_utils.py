# -*- coding: utf-8 -*-

# Copyright (C) 2010-2019 RhodeCode GmbH
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

import webob
from pyramid.threadlocal import get_current_request

from rhodecode import events
from rhodecode.lib import hooks_base
from rhodecode.lib import utils2


def _get_rc_scm_extras(username, repo_name, repo_alias, action):
    # TODO: johbo: Replace by vcs_operation_context and remove fully
    from rhodecode.lib.base import vcs_operation_context
    check_locking = action in ('pull', 'push')

    request = get_current_request()

    # default
    dummy_environ = webob.Request.blank('').environ
    try:
        environ = request.environ or dummy_environ
    except TypeError:
        # we might use this outside of request context
        environ = dummy_environ

    extras = vcs_operation_context(
        environ, repo_name, username, action, repo_alias, check_locking)
    return utils2.AttributeDict(extras)


def trigger_post_push_hook(
        username, action, hook_type, repo_name, repo_alias, commit_ids):
    """
    Triggers push action hooks

    :param username: username who pushes
    :param action: push/push_local/push_remote
    :param repo_name: name of repo
    :param repo_alias: the type of SCM repo
    :param commit_ids: list of commit ids that we pushed
    """
    extras = _get_rc_scm_extras(username, repo_name, repo_alias, action)
    extras.commit_ids = commit_ids
    extras.hook_type = hook_type
    hooks_base.post_push(extras)


def trigger_log_create_pull_request_hook(username, repo_name, repo_alias,
                                         pull_request, data=None):
    """
    Triggers create pull request action hooks

    :param username: username who creates the pull request
    :param repo_name: name of target repo
    :param repo_alias: the type of SCM target repo
    :param pull_request: the pull request that was created
    :param data: extra data for specific events e.g {'comment': comment_obj}
    """
    if repo_alias not in ('hg', 'git'):
        return

    extras = _get_rc_scm_extras(username, repo_name, repo_alias,
                                'create_pull_request')
    events.trigger(events.PullRequestCreateEvent(pull_request))
    extras.update(pull_request.get_api_data())
    hooks_base.log_create_pull_request(**extras)


def trigger_log_merge_pull_request_hook(username, repo_name, repo_alias,
                                        pull_request, data=None):
    """
    Triggers merge pull request action hooks

    :param username: username who creates the pull request
    :param repo_name: name of target repo
    :param repo_alias: the type of SCM target repo
    :param pull_request: the pull request that was merged
    :param data: extra data for specific events e.g {'comment': comment_obj}
    """
    if repo_alias not in ('hg', 'git'):
        return

    extras = _get_rc_scm_extras(username, repo_name, repo_alias,
                                'merge_pull_request')
    events.trigger(events.PullRequestMergeEvent(pull_request))
    extras.update(pull_request.get_api_data())
    hooks_base.log_merge_pull_request(**extras)


def trigger_log_close_pull_request_hook(username, repo_name, repo_alias,
                                        pull_request, data=None):
    """
    Triggers close pull request action hooks

    :param username: username who creates the pull request
    :param repo_name: name of target repo
    :param repo_alias: the type of SCM target repo
    :param pull_request: the pull request that was closed
    :param data: extra data for specific events e.g {'comment': comment_obj}
    """
    if repo_alias not in ('hg', 'git'):
        return

    extras = _get_rc_scm_extras(username, repo_name, repo_alias,
                                'close_pull_request')
    events.trigger(events.PullRequestCloseEvent(pull_request))
    extras.update(pull_request.get_api_data())
    hooks_base.log_close_pull_request(**extras)


def trigger_log_review_pull_request_hook(username, repo_name, repo_alias,
                                         pull_request, data=None):
    """
    Triggers review status change pull request action hooks

    :param username: username who creates the pull request
    :param repo_name: name of target repo
    :param repo_alias: the type of SCM target repo
    :param pull_request: the pull request that review status changed
    :param data: extra data for specific events e.g {'comment': comment_obj}
    """
    if repo_alias not in ('hg', 'git'):
        return

    extras = _get_rc_scm_extras(username, repo_name, repo_alias,
                                'review_pull_request')
    status = data.get('status')
    events.trigger(events.PullRequestReviewEvent(pull_request, status))
    extras.update(pull_request.get_api_data())
    hooks_base.log_review_pull_request(**extras)


def trigger_log_update_pull_request_hook(username, repo_name, repo_alias,
                                         pull_request, data=None):
    """
    Triggers update pull request action hooks

    :param username: username who creates the pull request
    :param repo_name: name of target repo
    :param repo_alias: the type of SCM target repo
    :param pull_request: the pull request that was updated
    :param data: extra data for specific events e.g {'comment': comment_obj}
    """
    if repo_alias not in ('hg', 'git'):
        return

    extras = _get_rc_scm_extras(username, repo_name, repo_alias,
                                'update_pull_request')
    events.trigger(events.PullRequestUpdateEvent(pull_request))
    extras.update(pull_request.get_api_data())
    hooks_base.log_update_pull_request(**extras)
