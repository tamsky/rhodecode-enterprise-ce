
<div class="pull-request-wrap">


    % if c.pr_merge_possible:
        <h2 class="merge-status">
            <span class="merge-icon success"><i class="icon-true"></i></span>
            ${_('This pull request can be merged automatically.')}
        </h2>
    % else:
        <h2 class="merge-status">
            <span class="merge-icon warning"><i class="icon-false"></i></span>
            ${_('Merge is not currently possible because of below failed checks.')}
        </h2>
    % endif

    <ul>
        % for pr_check_key, pr_check_details in c.pr_merge_errors.items():
            <% pr_check_type = pr_check_details['error_type'] %>
            <li>
                <span class="merge-message ${pr_check_type}" data-role="merge-message">
                    - ${pr_check_details['message']}
                    % if pr_check_key == 'todo':
                        % for co in pr_check_details['details']:
                            <a class="permalink" href="#comment-${co.comment_id}" onclick="Rhodecode.comments.scrollToComment($('#comment-${co.comment_id}'), 0, ${h.json.dumps(co.outdated)})"> #${co.comment_id}</a>${'' if loop.last else ','}
                        % endfor
                    % endif
                </span>
            </li>
        % endfor
    </ul>

    <div class="pull-request-merge-actions">
        % if c.allowed_to_merge:
        <div class="pull-right">
          ${h.secure_form(url('pullrequest_merge', repo_name=c.repo_name, pull_request_id=c.pull_request.pull_request_id), id='merge_pull_request_form')}
          <% merge_disabled = ' disabled' if c.pr_merge_possible is False else '' %>
          <a class="btn" href="#" onclick="refreshMergeChecks(); return false;">${_('refresh checks')}</a>
          <input type="submit" id="merge_pull_request" value="${_('Merge Pull Request')}" class="btn${merge_disabled}"${merge_disabled}>
          ${h.end_form()}
        </div>
        % elif c.rhodecode_user.username != h.DEFAULT_USER:
            <a class="btn" href="#" onclick="refreshMergeChecks(); return false;">${_('refresh checks')}</a>
            <input type="submit" value="${_('Merge Pull Request')}" class="btn disabled" disabled="disabled" title="${_('You are not allowed to merge this pull request.')}">
        % else:
          <input type="submit" value="${_('Login to Merge this Pull Request')}" class="btn disabled" disabled="disabled">
        % endif
    </div>
</div>
