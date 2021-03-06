## -*- coding: utf-8 -*-
<%inherit file="base.mako"/>
<%namespace name="base" file="base.mako"/>

<%def name="subject()" filter="n,trim,whitespace_filter">
<%
data = {
    'user': h.person(user),
    'pr_id': pull_request.pull_request_id,
    'pr_title': pull_request.title,
}
%>

${_('%(user)s wants you to review pull request #%(pr_id)s: "%(pr_title)s"') % data |n}
</%def>


<%def name="body_plaintext()" filter="n,trim">
<%
data = {
    'user': h.person(user),
    'pr_id': pull_request.pull_request_id,
    'pr_title': pull_request.title,
    'source_ref_type': pull_request.source_ref_parts.type,
    'source_ref_name': pull_request.source_ref_parts.name,
    'target_ref_type': pull_request.target_ref_parts.type,
    'target_ref_name': pull_request.target_ref_parts.name,
    'repo_url': pull_request_source_repo_url
}
%>
${self.subject()}


${h.literal(_('Pull request from %(source_ref_type)s:%(source_ref_name)s of %(repo_url)s into %(target_ref_type)s:%(target_ref_name)s') % data)}


* ${_('Link')}: ${pull_request_url}

* ${_('Title')}: ${pull_request.title}

* ${_('Description')}:

${pull_request.description}


* ${_ungettext('Commit (%(num)s)', 'Commits (%(num)s)', len(pull_request_commits) ) % {'num': len(pull_request_commits)}}:

% for commit_id, message in pull_request_commits:
        - ${h.short_id(commit_id)}
          ${h.chop_at_smart(message, '\n', suffix_if_chopped='...')}

% endfor

${self.plaintext_footer()}
</%def>
<%
data = {
    'user': h.person(user),
    'pr_id': pull_request.pull_request_id,
    'pr_title': pull_request.title,
    'source_ref_type': pull_request.source_ref_parts.type,
    'source_ref_name': pull_request.source_ref_parts.name,
    'target_ref_type': pull_request.target_ref_parts.type,
    'target_ref_name': pull_request.target_ref_parts.name,
    'repo_url': pull_request_source_repo_url,
    'source_repo_url': h.link_to(pull_request_source_repo.repo_name, pull_request_source_repo_url),
    'target_repo_url': h.link_to(pull_request_target_repo.repo_name, pull_request_target_repo_url)
}
%>
<table style="text-align:left;vertical-align:middle;">
    <tr><td colspan="2" style="width:100%;padding-bottom:15px;border-bottom:1px solid #dbd9da;"><h4><a href="${pull_request_url}" style="color:#427cc9;text-decoration:none;cursor:pointer">${_('%(user)s wants you to review pull request #%(pr_id)s: "%(pr_title)s".') % data }</a></h4></td></tr>
    <tr><td style="padding-right:20px;padding-top:15px;">${_('Title')}</td><td style="padding-top:15px;">${pull_request.title}</td></tr>
    <tr><td style="padding-right:20px;">${_('Source')}</td><td>${base.tag_button(pull_request.source_ref_parts.name)} ${h.literal(_('%(source_ref_type)s of %(source_repo_url)s') % data)}</td></tr>
    <tr><td style="padding-right:20px;">${_('Target')}</td><td>${base.tag_button(pull_request.target_ref_parts.name)} ${h.literal(_('%(target_ref_type)s of %(target_repo_url)s') % data)}</td></tr>
    <tr><td style="padding-right:20px;">${_('Description')}</td><td style="white-space:pre-wrap">${pull_request.description}</td></tr>
    <tr><td style="padding-right:20px;">${_ungettext('%(num)s Commit', '%(num)s Commits', len(pull_request_commits)) % {'num': len(pull_request_commits)}}</td>
        <td><ol style="margin:0 0 0 1em;padding:0;text-align:left;">
            % for commit_id, message in pull_request_commits:
            <li style="margin:0 0 1em;"><pre style="margin:0 0 .5em">${h.short_id(commit_id)}</pre>
                ${h.chop_at_smart(message, '\n', suffix_if_chopped='...')}
            </li>
            % endfor
        </ol></td>
    </tr>
</table>
