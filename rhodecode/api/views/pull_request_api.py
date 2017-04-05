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

from rhodecode.api import jsonrpc_method, JSONRPCError
from rhodecode.api.utils import (
    has_superadmin_permission, Optional, OAttr, get_repo_or_error,
    get_pull_request_or_error, get_commit_or_error, get_user_or_error,
    validate_repo_permissions, resolve_ref_or_error)
from rhodecode.lib.auth import (HasRepoPermissionAnyApi)
from rhodecode.lib.base import vcs_operation_context
from rhodecode.lib.utils2 import str2bool
from rhodecode.model.changeset_status import ChangesetStatusModel
from rhodecode.model.comment import CommentsModel
from rhodecode.model.db import Session, ChangesetStatus, ChangesetComment
from rhodecode.model.pull_request import PullRequestModel, MergeCheck
from rhodecode.model.settings import SettingsModel

log = logging.getLogger(__name__)


@jsonrpc_method()
def get_pull_request(request, apiuser, repoid, pullrequestid):
    """
    Get a pull request based on the given ID.

    :param apiuser: This is filled automatically from the |authtoken|.
    :type apiuser: AuthUser
    :param repoid: Repository name or repository ID from where the pull
        request was opened.
    :type repoid: str or int
    :param pullrequestid: ID of the requested pull request.
    :type pullrequestid: int

    Example output:

    .. code-block:: bash

      "id": <id_given_in_input>,
      "result":
        {
            "pull_request_id":   "<pull_request_id>",
            "url":               "<url>",
            "title":             "<title>",
            "description":       "<description>",
            "status" :           "<status>",
            "created_on":        "<date_time_created>",
            "updated_on":        "<date_time_updated>",
            "commit_ids":        [
                                     ...
                                     "<commit_id>",
                                     "<commit_id>",
                                     ...
                                 ],
            "review_status":    "<review_status>",
            "mergeable":         {
                                     "status":  "<bool>",
                                     "message": "<message>",
                                 },
            "source":            {
                                     "clone_url":     "<clone_url>",
                                     "repository":    "<repository_name>",
                                     "reference":
                                     {
                                         "name":      "<name>",
                                         "type":      "<type>",
                                         "commit_id": "<commit_id>",
                                     }
                                 },
            "target":            {
                                     "clone_url":   "<clone_url>",
                                     "repository":    "<repository_name>",
                                     "reference":
                                     {
                                         "name":      "<name>",
                                         "type":      "<type>",
                                         "commit_id": "<commit_id>",
                                     }
                                 },
            "merge":             {
                                     "clone_url":   "<clone_url>",
                                     "reference":
                                     {
                                         "name":      "<name>",
                                         "type":      "<type>",
                                         "commit_id": "<commit_id>",
                                     }
                                 },
           "author":             <user_obj>,
           "reviewers":          [
                                     ...
                                     {
                                        "user":          "<user_obj>",
                                        "review_status": "<review_status>",
                                     }
                                     ...
                                 ]
        },
       "error": null
    """
    get_repo_or_error(repoid)
    pull_request = get_pull_request_or_error(pullrequestid)
    if not PullRequestModel().check_user_read(
            pull_request, apiuser, api=True):
        raise JSONRPCError('repository `%s` does not exist' % (repoid,))
    data = pull_request.get_api_data()
    return data


@jsonrpc_method()
def get_pull_requests(request, apiuser, repoid, status=Optional('new')):
    """
    Get all pull requests from the repository specified in `repoid`.

    :param apiuser: This is filled automatically from the |authtoken|.
    :type apiuser: AuthUser
    :param repoid: Repository name or repository ID.
    :type repoid: str or int
    :param status: Only return pull requests with the specified status.
        Valid options are.
        * ``new`` (default)
        * ``open``
        * ``closed``
    :type status: str

    Example output:

    .. code-block:: bash

      "id": <id_given_in_input>,
      "result":
        [
            ...
            {
                "pull_request_id":   "<pull_request_id>",
                "url":               "<url>",
                "title" :            "<title>",
                "description":       "<description>",
                "status":            "<status>",
                "created_on":        "<date_time_created>",
                "updated_on":        "<date_time_updated>",
                "commit_ids":        [
                                         ...
                                         "<commit_id>",
                                         "<commit_id>",
                                         ...
                                     ],
                "review_status":    "<review_status>",
                "mergeable":         {
                                        "status":      "<bool>",
                                        "message:      "<message>",
                                     },
                "source":            {
                                         "clone_url":     "<clone_url>",
                                         "reference":
                                         {
                                             "name":      "<name>",
                                             "type":      "<type>",
                                             "commit_id": "<commit_id>",
                                         }
                                     },
                "target":            {
                                         "clone_url":   "<clone_url>",
                                         "reference":
                                         {
                                             "name":      "<name>",
                                             "type":      "<type>",
                                             "commit_id": "<commit_id>",
                                         }
                                     },
                "merge":             {
                                         "clone_url":   "<clone_url>",
                                         "reference":
                                         {
                                             "name":      "<name>",
                                             "type":      "<type>",
                                             "commit_id": "<commit_id>",
                                         }
                                     },
               "author":             <user_obj>,
               "reviewers":          [
                                         ...
                                         {
                                            "user":          "<user_obj>",
                                            "review_status": "<review_status>",
                                         }
                                         ...
                                     ]
            }
            ...
        ],
      "error": null

    """
    repo = get_repo_or_error(repoid)
    if not has_superadmin_permission(apiuser):
        _perms = (
            'repository.admin', 'repository.write', 'repository.read',)
        validate_repo_permissions(apiuser, repoid, repo, _perms)

    status = Optional.extract(status)
    pull_requests = PullRequestModel().get_all(repo, statuses=[status])
    data = [pr.get_api_data() for pr in pull_requests]
    return data


@jsonrpc_method()
def merge_pull_request(request, apiuser, repoid, pullrequestid,
                       userid=Optional(OAttr('apiuser'))):
    """
    Merge the pull request specified by `pullrequestid` into its target
    repository.

    :param apiuser: This is filled automatically from the |authtoken|.
    :type apiuser: AuthUser
    :param repoid: The Repository name or repository ID of the
        target repository to which the |pr| is to be merged.
    :type repoid: str or int
    :param pullrequestid: ID of the pull request which shall be merged.
    :type pullrequestid: int
    :param userid: Merge the pull request as this user.
    :type userid: Optional(str or int)

    Example output:

    .. code-block:: bash

        "id": <id_given_in_input>,
        "result": {
            "executed":         "<bool>",
            "failure_reason":   "<int>",
            "merge_commit_id":  "<merge_commit_id>",
            "possible":         "<bool>",
            "merge_ref":        {
                                    "commit_id": "<commit_id>",
                                    "type":      "<type>",
                                    "name":      "<name>"
                                }
        },
        "error": null
    """
    repo = get_repo_or_error(repoid)
    if not isinstance(userid, Optional):
        if (has_superadmin_permission(apiuser) or
                HasRepoPermissionAnyApi('repository.admin')(
                    user=apiuser, repo_name=repo.repo_name)):
            apiuser = get_user_or_error(userid)
        else:
            raise JSONRPCError('userid is not the same as your user')

    pull_request = get_pull_request_or_error(pullrequestid)

    check = MergeCheck.validate(pull_request, user=apiuser)
    merge_possible = not check.failed

    if not merge_possible:
        reasons = ','.join([msg for _e, msg in check.errors])
        raise JSONRPCError(
            'merge not possible for following reasons: {}'.format(reasons))

    target_repo = pull_request.target_repo
    extras = vcs_operation_context(
        request.environ, repo_name=target_repo.repo_name,
        username=apiuser.username, action='push',
        scm=target_repo.repo_type)
    merge_response = PullRequestModel().merge(
        pull_request, apiuser, extras=extras)
    if merge_response.executed:
        PullRequestModel().close_pull_request(
            pull_request.pull_request_id, apiuser)

        Session().commit()

    # In previous versions the merge response directly contained the merge
    # commit id. It is now contained in the merge reference object. To be
    # backwards compatible we have to extract it again.
    merge_response = merge_response._asdict()
    merge_response['merge_commit_id'] = merge_response['merge_ref'].commit_id

    return merge_response


@jsonrpc_method()
def close_pull_request(request, apiuser, repoid, pullrequestid,
                       userid=Optional(OAttr('apiuser'))):
    """
    Close the pull request specified by `pullrequestid`.

    :param apiuser: This is filled automatically from the |authtoken|.
    :type apiuser: AuthUser
    :param repoid: Repository name or repository ID to which the pull
        request belongs.
    :type repoid: str or int
    :param pullrequestid: ID of the pull request to be closed.
    :type pullrequestid: int
    :param userid: Close the pull request as this user.
    :type userid: Optional(str or int)

    Example output:

    .. code-block:: bash

        "id": <id_given_in_input>,
        "result": {
            "pull_request_id":  "<int>",
            "closed":           "<bool>"
        },
        "error": null

    """
    repo = get_repo_or_error(repoid)
    if not isinstance(userid, Optional):
        if (has_superadmin_permission(apiuser) or
                HasRepoPermissionAnyApi('repository.admin')(
                    user=apiuser, repo_name=repo.repo_name)):
            apiuser = get_user_or_error(userid)
        else:
            raise JSONRPCError('userid is not the same as your user')

    pull_request = get_pull_request_or_error(pullrequestid)
    if not PullRequestModel().check_user_update(
            pull_request, apiuser, api=True):
        raise JSONRPCError(
            'pull request `%s` close failed, no permission to close.' % (
                pullrequestid,))
    if pull_request.is_closed():
        raise JSONRPCError(
            'pull request `%s` is already closed' % (pullrequestid,))

    PullRequestModel().close_pull_request(
        pull_request.pull_request_id, apiuser)
    Session().commit()
    data = {
        'pull_request_id': pull_request.pull_request_id,
        'closed': True,
    }
    return data


@jsonrpc_method()
def comment_pull_request(
        request, apiuser, repoid, pullrequestid, message=Optional(None),
        commit_id=Optional(None), status=Optional(None),
        comment_type=Optional(ChangesetComment.COMMENT_TYPE_NOTE),
        resolves_comment_id=Optional(None),
        userid=Optional(OAttr('apiuser'))):
    """
    Comment on the pull request specified with the `pullrequestid`,
    in the |repo| specified by the `repoid`, and optionally change the
    review status.

    :param apiuser: This is filled automatically from the |authtoken|.
    :type apiuser: AuthUser
    :param repoid: The repository name or repository ID.
    :type repoid: str or int
    :param pullrequestid: The pull request ID.
    :type pullrequestid: int
    :param commit_id: Specify the commit_id for which to set a comment. If
        given commit_id is different than latest in the PR status
        change won't be performed.
    :type commit_id: str
    :param message: The text content of the comment.
    :type message: str
    :param status: (**Optional**) Set the approval status of the pull
        request. One of: 'not_reviewed', 'approved', 'rejected',
        'under_review'
    :type status: str
    :param comment_type: Comment type, one of: 'note', 'todo'
    :type comment_type: Optional(str), default: 'note'
    :param userid: Comment on the pull request as this user
    :type userid: Optional(str or int)

    Example output:

    .. code-block:: bash

        id : <id_given_in_input>
        result : {
            "pull_request_id":  "<Integer>",
            "comment_id":       "<Integer>",
            "status": {"given": <given_status>,
                       "was_changed": <bool status_was_actually_changed> },
        },
        error :  null
    """
    repo = get_repo_or_error(repoid)
    if not isinstance(userid, Optional):
        if (has_superadmin_permission(apiuser) or
                HasRepoPermissionAnyApi('repository.admin')(
                    user=apiuser, repo_name=repo.repo_name)):
            apiuser = get_user_or_error(userid)
        else:
            raise JSONRPCError('userid is not the same as your user')

    pull_request = get_pull_request_or_error(pullrequestid)
    if not PullRequestModel().check_user_read(
            pull_request, apiuser, api=True):
        raise JSONRPCError('repository `%s` does not exist' % (repoid,))
    message = Optional.extract(message)
    status = Optional.extract(status)
    commit_id = Optional.extract(commit_id)
    comment_type = Optional.extract(comment_type)
    resolves_comment_id = Optional.extract(resolves_comment_id)

    if not message and not status:
        raise JSONRPCError(
            'Both message and status parameters are missing. '
            'At least one is required.')

    if (status not in (st[0] for st in ChangesetStatus.STATUSES) and
            status is not None):
        raise JSONRPCError('Unknown comment status: `%s`' % status)

    if commit_id and commit_id not in pull_request.revisions:
        raise JSONRPCError(
            'Invalid commit_id `%s` for this pull request.' % commit_id)

    allowed_to_change_status = PullRequestModel().check_user_change_status(
        pull_request, apiuser)

    # if commit_id is passed re-validated if user is allowed to change status
    # based on latest commit_id from the PR
    if commit_id:
        commit_idx = pull_request.revisions.index(commit_id)
        if commit_idx != 0:
            allowed_to_change_status = False

    if resolves_comment_id:
        comment = ChangesetComment.get(resolves_comment_id)
        if not comment:
            raise JSONRPCError(
                'Invalid resolves_comment_id `%s` for this pull request.'
                % resolves_comment_id)
        if comment.comment_type != ChangesetComment.COMMENT_TYPE_TODO:
            raise JSONRPCError(
                'Comment `%s` is wrong type for setting status to resolved.'
                % resolves_comment_id)

    text = message
    status_label = ChangesetStatus.get_status_lbl(status)
    if status and allowed_to_change_status:
        st_message = ('Status change %(transition_icon)s %(status)s'
                      % {'transition_icon': '>', 'status': status_label})
        text = message or st_message

    rc_config = SettingsModel().get_all_settings()
    renderer = rc_config.get('rhodecode_markup_renderer', 'rst')

    status_change = status and allowed_to_change_status
    comment = CommentsModel().create(
        text=text,
        repo=pull_request.target_repo.repo_id,
        user=apiuser.user_id,
        pull_request=pull_request.pull_request_id,
        f_path=None,
        line_no=None,
        status_change=(status_label if status_change else None),
        status_change_type=(status if status_change else None),
        closing_pr=False,
        renderer=renderer,
        comment_type=comment_type,
        resolves_comment_id=resolves_comment_id
    )

    if allowed_to_change_status and status:
        ChangesetStatusModel().set_status(
            pull_request.target_repo.repo_id,
            status,
            apiuser.user_id,
            comment,
            pull_request=pull_request.pull_request_id
        )
        Session().flush()

    Session().commit()
    data = {
        'pull_request_id': pull_request.pull_request_id,
        'comment_id': comment.comment_id if comment else None,
        'status': {'given': status, 'was_changed': status_change},
    }
    return data


@jsonrpc_method()
def create_pull_request(
        request, apiuser, source_repo, target_repo, source_ref, target_ref,
        title, description=Optional(''), reviewers=Optional(None)):
    """
    Creates a new pull request.

    Accepts refs in the following formats:

        * branch:<branch_name>:<sha>
        * branch:<branch_name>
        * bookmark:<bookmark_name>:<sha> (Mercurial only)
        * bookmark:<bookmark_name> (Mercurial only)

    :param apiuser: This is filled automatically from the |authtoken|.
    :type apiuser: AuthUser
    :param source_repo: Set the source repository name.
    :type source_repo: str
    :param target_repo: Set the target repository name.
    :type target_repo: str
    :param source_ref: Set the source ref name.
    :type source_ref: str
    :param target_ref: Set the target ref name.
    :type target_ref: str
    :param title: Set the pull request title.
    :type title: str
    :param description: Set the pull request description.
    :type description: Optional(str)
    :param reviewers: Set the new pull request reviewers list.
    :type reviewers: Optional(list)
        Accepts username strings or objects of the format:

            {'username': 'nick', 'reasons': ['original author']}
    """

    source = get_repo_or_error(source_repo)
    target = get_repo_or_error(target_repo)
    if not has_superadmin_permission(apiuser):
        _perms = ('repository.admin', 'repository.write', 'repository.read',)
        validate_repo_permissions(apiuser, source_repo, source, _perms)

    full_source_ref = resolve_ref_or_error(source_ref, source)
    full_target_ref = resolve_ref_or_error(target_ref, target)
    source_commit = get_commit_or_error(full_source_ref, source)
    target_commit = get_commit_or_error(full_target_ref, target)
    source_scm = source.scm_instance()
    target_scm = target.scm_instance()

    commit_ranges = target_scm.compare(
        target_commit.raw_id, source_commit.raw_id, source_scm,
        merge=True, pre_load=[])

    ancestor = target_scm.get_common_ancestor(
        target_commit.raw_id, source_commit.raw_id, source_scm)

    if not commit_ranges:
        raise JSONRPCError('no commits found')

    if not ancestor:
        raise JSONRPCError('no common ancestor found')

    reviewer_objects = Optional.extract(reviewers) or []
    if not isinstance(reviewer_objects, list):
        raise JSONRPCError('reviewers should be specified as a list')

    reviewers_reasons = []
    for reviewer_object in reviewer_objects:
        reviewer_reasons = []
        if isinstance(reviewer_object, (basestring, int)):
            reviewer_username = reviewer_object
        else:
            reviewer_username = reviewer_object['username']
            reviewer_reasons = reviewer_object.get('reasons', [])

        user = get_user_or_error(reviewer_username)
        reviewers_reasons.append((user.user_id, reviewer_reasons))

    pull_request_model = PullRequestModel()
    pull_request = pull_request_model.create(
        created_by=apiuser.user_id,
        source_repo=source_repo,
        source_ref=full_source_ref,
        target_repo=target_repo,
        target_ref=full_target_ref,
        revisions=reversed(
            [commit.raw_id for commit in reversed(commit_ranges)]),
        reviewers=reviewers_reasons,
        title=title,
        description=Optional.extract(description)
    )

    Session().commit()
    data = {
        'msg': 'Created new pull request `{}`'.format(title),
        'pull_request_id': pull_request.pull_request_id,
    }
    return data


@jsonrpc_method()
def update_pull_request(
        request, apiuser, repoid, pullrequestid, title=Optional(''),
        description=Optional(''), reviewers=Optional(None),
        update_commits=Optional(None), close_pull_request=Optional(None)):
    """
    Updates a pull request.

    :param apiuser: This is filled automatically from the |authtoken|.
    :type apiuser: AuthUser
    :param repoid: The repository name or repository ID.
    :type repoid: str or int
    :param pullrequestid: The pull request ID.
    :type pullrequestid: int
    :param title: Set the pull request title.
    :type title: str
    :param description: Update pull request description.
    :type description: Optional(str)
    :param reviewers: Update pull request reviewers list with new value.
    :type reviewers: Optional(list)
    :param update_commits: Trigger update of commits for this pull request
    :type: update_commits: Optional(bool)
    :param close_pull_request: Close this pull request with rejected state
    :type: close_pull_request: Optional(bool)

    Example output:

    .. code-block:: bash

        id : <id_given_in_input>
        result : {
            "msg": "Updated pull request `63`",
            "pull_request": <pull_request_object>,
            "updated_reviewers": {
              "added": [
                "username"
              ],
              "removed": []
            },
            "updated_commits": {
              "added": [
                "<sha1_hash>"
              ],
              "common": [
                "<sha1_hash>",
                "<sha1_hash>",
              ],
              "removed": []
            }
        }
        error :  null
    """

    repo = get_repo_or_error(repoid)
    pull_request = get_pull_request_or_error(pullrequestid)
    if not PullRequestModel().check_user_update(
            pull_request, apiuser, api=True):
        raise JSONRPCError(
            'pull request `%s` update failed, no permission to update.' % (
                pullrequestid,))
    if pull_request.is_closed():
        raise JSONRPCError(
            'pull request `%s` update failed, pull request is closed' % (
                pullrequestid,))

    reviewer_objects = Optional.extract(reviewers) or []
    if not isinstance(reviewer_objects, list):
        raise JSONRPCError('reviewers should be specified as a list')

    reviewers_reasons = []
    reviewer_ids = set()
    for reviewer_object in reviewer_objects:
        reviewer_reasons = []
        if isinstance(reviewer_object, (int, basestring)):
            reviewer_username = reviewer_object
        else:
            reviewer_username = reviewer_object['username']
            reviewer_reasons = reviewer_object.get('reasons', [])

        user = get_user_or_error(reviewer_username)
        reviewer_ids.add(user.user_id)
        reviewers_reasons.append((user.user_id, reviewer_reasons))

    title = Optional.extract(title)
    description = Optional.extract(description)
    if title or description:
        PullRequestModel().edit(
            pull_request, title or pull_request.title,
            description or pull_request.description)
        Session().commit()

    commit_changes = {"added": [], "common": [], "removed": []}
    if str2bool(Optional.extract(update_commits)):
        if PullRequestModel().has_valid_update_type(pull_request):
            update_response = PullRequestModel().update_commits(
                pull_request)
            commit_changes = update_response.changes or commit_changes
        Session().commit()

    reviewers_changes = {"added": [], "removed": []}
    if reviewer_ids:
        added_reviewers, removed_reviewers = \
            PullRequestModel().update_reviewers(pull_request, reviewers_reasons)

        reviewers_changes['added'] = sorted(
            [get_user_or_error(n).username for n in added_reviewers])
        reviewers_changes['removed'] = sorted(
            [get_user_or_error(n).username for n in removed_reviewers])
        Session().commit()

    if str2bool(Optional.extract(close_pull_request)):
        PullRequestModel().close_pull_request_with_comment(
            pull_request, apiuser, repo)
        Session().commit()

    data = {
        'msg': 'Updated pull request `{}`'.format(
            pull_request.pull_request_id),
        'pull_request': pull_request.get_api_data(),
        'updated_commits': commit_changes,
        'updated_reviewers': reviewers_changes
    }

    return data
