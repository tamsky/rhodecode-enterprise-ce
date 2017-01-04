<%namespace name="base" file="/base/base.mako"/>

<div class="summary-detail-header">
    <h4 class="item">
        % if c.file_author:
            ${_('Last Author')}
        % else:
            ${h.literal(ungettext(u'File Author (%s)',u'File Authors (%s)',len(c.authors)) % ('<b>%s</b>' % len(c.authors))) }
        % endif
    </h4>
    <a href="#" id="show_authors" class="action_link">${_('Show All')}</a>
</div>

% if c.authors:
<ul class="sidebar-right-content">
    % for email, user in sorted(c.authors, key=lambda e: c.file_last_commit.author_email!=e[0]):
    <li class="file_author">
        <div class="rc-user tooltip" title="${h.author_string(email)}">
          ${base.gravatar(email, 16)}
          <span class="user">${h.link_to_user(user)}</span>
        </div>
        % if c.file_author: 
            <div class="user-inline-data">- ${h.age_component(c.file_last_commit.date)}</div>
        % elif c.file_last_commit.author_email==email:
            <div class="user-inline-data"> (${_('last author')})</div>
        % endif
    </li>
    % endfor
</ul>
% endif
