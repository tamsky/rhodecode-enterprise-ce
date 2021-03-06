## -*- coding: utf-8 -*-
<%inherit file="base.mako"/>
<%namespace name="base" file="base.mako"/>

## EMAIL SUBJECT
<%def name="subject()" filter="n,trim,whitespace_filter">
<%
data = {
    'user': h.person(user),
    'pr_title': pull_request.title,
    'pr_id': pull_request.pull_request_id,
    'status': status_change,
    'comment_file': comment_file,
    'comment_line': comment_line,
    'comment_type': comment_type,
}
%>

${(_('[mention]') if mention else '')} \

% if comment_file:
    ${_('{user} left a {comment_type} on file `{comment_file}` in pull request #{pr_id} "{pr_title}"').format(**data) |n}
% else:
    % if status_change:
    ${_('[status: {status}] {user} left a {comment_type} on pull request #{pr_id} "{pr_title}"').format(**data) |n}
    % else:
    ${_('{user} left a {comment_type} on pull request #{pr_id} "{pr_title}"').format(**data) |n}
    % endif
% endif
</%def>

## PLAINTEXT VERSION OF BODY
<%def name="body_plaintext()" filter="n,trim">
<%
data = {
    'user': h.person(user),
    'pr_title': pull_request.title,
    'pr_id': pull_request.pull_request_id,
    'status': status_change,
    'comment_file': comment_file,
    'comment_line': comment_line,
    'comment_type': comment_type,
}
%>
${self.subject()}

* ${_('Comment link')}: ${pr_comment_url}

* ${_('Source repository')}: ${pr_source_repo_url}

%if comment_file:
* ${_('File: {comment_file} on line {comment_line}').format(comment_file=comment_file, comment_line=comment_line)}
%endif

---

%if status_change and not closing_pr:
   ${_('{user} submitted pull request #{pr_id} status: *{status}*').format(**data)}
%elif status_change and closing_pr:
   ${_('{user} submitted pull request #{pr_id} status: *{status} and closed*').format(**data)}
%endif

${comment_body |n}

${self.plaintext_footer()}
</%def>


<%
data = {
    'user': h.person(user),
    'pr_title': pull_request.title,
    'pr_id': pull_request.pull_request_id,
    'status': status_change,
    'comment_file': comment_file,
    'comment_line': comment_line,
    'comment_type': comment_type,
}
%>
<table style="text-align:left;vertical-align:middle;">
    <tr><td colspan="2" style="width:100%;padding-bottom:15px;border-bottom:1px solid #dbd9da;">

    % if comment_file:
        <h4><a href="${pr_comment_url}" style="color:#427cc9;text-decoration:none;cursor:pointer">${_('{user} left a {comment_type} on file `{comment_file}` in pull request #{pr_id} "{pr_title}"').format(**data) |n}</a></h4>
    % else:
        <h4><a href="${pr_comment_url}" style="color:#427cc9;text-decoration:none;cursor:pointer">${_('{user} left a {comment_type} on pull request #{pr_id} "{pr_title}"').format(**data) |n}</a></h4>
    % endif

    </td></tr>
    <tr><td style="padding-right:20px;padding-top:15px;">${_('Source')}</td><td style="padding-top:15px;"><a style="color:#427cc9;text-decoration:none;cursor:pointer" href="${pr_source_repo_url}">${pr_source_repo.repo_name}</a></td></tr>

    % if status_change:
        <tr>
            <td style="padding-right:20px;">${_('Status')}</td>
            <td>
                % if closing_pr:
                   ${_('Closed pull request with status')}: ${base.status_text(status_change, tag_type=status_change_type)}
                % else:
                   ${_('Submitted review status')}: ${base.status_text(status_change, tag_type=status_change_type)}
                % endif
            </td>
        </tr>
    % endif
    <tr>
        <td style="padding-right:20px;">
            % if comment_type == 'todo':
                ${(_('TODO comment on line: {comment_line}') if comment_file else _('TODO comment')).format(**data)}
            % else:
                ${(_('Note comment on line: {comment_line}') if comment_file else _('Note comment')).format(**data)}
            % endif
        </td>
        <td style="line-height:1.2em;white-space:pre-wrap">${h.render(comment_body, renderer=renderer_type, mentions=True)}</td>
    </tr>
</table>
