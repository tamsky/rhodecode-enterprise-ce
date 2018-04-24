## DATA TABLE RE USABLE ELEMENTS
## usage:
## <%namespace name="dt" file="/data_table/_dt_elements.mako"/>
<%namespace name="base" file="/base/base.mako"/>

<%def name="metatags_help()">
    <table>
        <%
            example_tags = [
                ('state','[stable]'),
                ('state','[stale]'),
                ('state','[featured]'),
                ('state','[dev]'),
                ('state','[dead]'),
                ('state','[deprecated]'),

                ('label','[personal]'),
                ('generic','[v2.0.0]'),

                ('lang','[lang =&gt; JavaScript]'),
                ('license','[license =&gt; LicenseName]'),

                ('ref','[requires =&gt; RepoName]'),
                ('ref','[recommends =&gt; GroupName]'),
                ('ref','[conflicts =&gt; SomeName]'),
                ('ref','[base =&gt; SomeName]'),
                ('url','[url =&gt; [linkName](https://rhodecode.com)]'),
                ('see','[see =&gt; http://rhodecode.com]'),
            ]
        %>
        % for tag_type, tag in example_tags:
            <tr>
                <td>${tag|n}</td>
                <td>${h.style_metatag(tag_type, tag)|n}</td>
            </tr>
        % endfor
    </table>
</%def>

## REPOSITORY RENDERERS
<%def name="quick_menu(repo_name)">
  <i class="icon-more"></i>
  <div class="menu_items_container hidden">
    <ul class="menu_items">
      <li>
         <a title="${_('Summary')}" href="${h.route_path('repo_summary',repo_name=repo_name)}">
         <span>${_('Summary')}</span>
         </a>
      </li>
      <li>
         <a title="${_('Changelog')}" href="${h.route_path('repo_changelog',repo_name=repo_name)}">
         <span>${_('Changelog')}</span>
         </a>
      </li>
      <li>
         <a title="${_('Files')}" href="${h.route_path('repo_files:default_commit',repo_name=repo_name)}">
         <span>${_('Files')}</span>
         </a>
      </li>
      <li>
         <a title="${_('Fork')}" href="${h.route_path('repo_fork_new',repo_name=repo_name)}">
         <span>${_('Fork')}</span>
         </a>
      </li>
    </ul>
  </div>
</%def>

<%def name="repo_name(name,rtype,rstate,private,fork_of,short_name=False,admin=False)">
    <%
    def get_name(name,short_name=short_name):
      if short_name:
        return name.split('/')[-1]
      else:
        return name
    %>
  <div class="${'repo_state_pending' if rstate == 'repo_state_pending' else ''} truncate">
    ##NAME
    <a href="${h.route_path('edit_repo',repo_name=name) if admin else h.route_path('repo_summary',repo_name=name)}">

    ##TYPE OF REPO
    %if h.is_hg(rtype):
        <span title="${_('Mercurial repository')}"><i class="icon-hg" style="font-size: 14px;"></i></span>
    %elif h.is_git(rtype):
        <span title="${_('Git repository')}"><i class="icon-git" style="font-size: 14px"></i></span>
    %elif h.is_svn(rtype):
        <span title="${_('Subversion repository')}"><i class="icon-svn" style="font-size: 14px"></i></span>
    %endif

    ##PRIVATE/PUBLIC
    %if private and c.visual.show_private_icon:
      <i class="icon-lock" title="${_('Private repository')}"></i>
    %elif not private and c.visual.show_public_icon:
      <i class="icon-unlock-alt" title="${_('Public repository')}"></i>
    %else:
      <span></span>
    %endif
    ${get_name(name)}
    </a>
    %if fork_of:
      <a href="${h.route_path('repo_summary',repo_name=fork_of.repo_name)}"><i class="icon-code-fork"></i></a>
    %endif
    %if rstate == 'repo_state_pending':
      <span class="creation_in_progress tooltip" title="${_('This repository is being created in a background task')}">
          (${_('creating...')})
      </span>
    %endif
  </div>
</%def>

<%def name="repo_desc(description, stylify_metatags)">
    <%
    tags, description = h.extract_metatags(description)
    %>

    <div class="truncate-wrap">
        % if stylify_metatags:
            % for tag_type, tag in tags:
                ${h.style_metatag(tag_type, tag)|n}
            % endfor
        % endif
        ${description}
    </div>

</%def>

<%def name="last_change(last_change)">
    ${h.age_component(last_change, time_is_local=True)}
</%def>

<%def name="revision(name,rev,tip,author,last_msg, commit_date)">
  <div>
  %if rev >= 0:
      <code><a title="${h.tooltip('%s\n%s\n\n%s' % (author, commit_date, last_msg))}" class="tooltip" href="${h.route_path('repo_commit',repo_name=name,commit_id=tip)}">${'r%s:%s' % (rev,h.short_id(tip))}</a></code>
  %else:
      ${_('No commits yet')}
  %endif
  </div>
</%def>

<%def name="rss(name)">
  %if c.rhodecode_user.username != h.DEFAULT_USER:
    <a title="${h.tooltip(_('Subscribe to %s rss feed')% name)}" href="${h.route_path('rss_feed_home', repo_name=name, _query=dict(auth_token=c.rhodecode_user.feed_token))}"><i class="icon-rss-sign"></i></a>
  %else:
    <a title="${h.tooltip(_('Subscribe to %s rss feed')% name)}" href="${h.route_path('rss_feed_home', repo_name=name)}"><i class="icon-rss-sign"></i></a>
  %endif
</%def>

<%def name="atom(name)">
  %if c.rhodecode_user.username != h.DEFAULT_USER:
    <a title="${h.tooltip(_('Subscribe to %s atom feed')% name)}" href="${h.route_path('atom_feed_home', repo_name=name, _query=dict(auth_token=c.rhodecode_user.feed_token))}"><i class="icon-rss-sign"></i></a>
  %else:
    <a title="${h.tooltip(_('Subscribe to %s atom feed')% name)}" href="${h.route_path('atom_feed_home', repo_name=name)}"><i class="icon-rss-sign"></i></a>
  %endif
</%def>

<%def name="user_gravatar(email, size=16)">
  <div class="rc-user tooltip" title="${h.tooltip(h.author_string(email))}">
    ${base.gravatar(email, 16)}
  </div>
</%def>

<%def name="repo_actions(repo_name, super_user=True)">
  <div>
    <div class="grid_edit">
      <a href="${h.route_path('edit_repo',repo_name=repo_name)}" title="${_('Edit')}">
        <i class="icon-pencil"></i>Edit</a>
    </div>
    <div class="grid_delete">
      ${h.secure_form(h.route_path('edit_repo_advanced_delete', repo_name=repo_name), request=request)}
        ${h.submit('remove_%s' % repo_name,_('Delete'),class_="btn btn-link btn-danger",
        onclick="return confirm('"+_('Confirm to delete this repository: %s') % repo_name+"');")}
      ${h.end_form()}
    </div>
  </div>
</%def>

<%def name="repo_state(repo_state)">
  <div>
    %if repo_state == 'repo_state_pending':
        <div class="tag tag4">${_('Creating')}</div>
    %elif repo_state == 'repo_state_created':
        <div class="tag tag1">${_('Created')}</div>
    %else:
        <div class="tag alert2" title="${h.tooltip(repo_state)}">invalid</div>
    %endif
  </div>
</%def>


## REPO GROUP RENDERERS
<%def name="quick_repo_group_menu(repo_group_name)">
  <i class="icon-more"></i>
  <div class="menu_items_container hidden">
    <ul class="menu_items">
      <li>
         <a href="${h.route_path('repo_group_home', repo_group_name=repo_group_name)}">${_('Summary')}</a>
      </li>

    </ul>
  </div>
</%def>

<%def name="repo_group_name(repo_group_name, children_groups=None)">
  <div>
    <a href="${h.route_path('repo_group_home', repo_group_name=repo_group_name)}">
    <i class="icon-folder-close" title="${_('Repository group')}" style="font-size: 16px"></i>
      %if children_groups:
          ${h.literal(' &raquo; '.join(children_groups))}
      %else:
          ${repo_group_name}
      %endif
  </a>
  </div>
</%def>

<%def name="repo_group_desc(description, personal, stylify_metatags)">

    <%
    tags, description = h.extract_metatags(description)
    %>

    <div class="truncate-wrap">
        % if personal:
            <div class="metatag" tag="personal">${_('personal')}</div>
        % endif

        % if stylify_metatags:
            % for tag_type, tag in tags:
                ${h.style_metatag(tag_type, tag)|n}
            % endfor
        % endif
        ${description}
    </div>

</%def>

<%def name="repo_group_actions(repo_group_id, repo_group_name, gr_count)">
 <div class="grid_edit">
    <a href="${h.route_path('edit_repo_group',repo_group_name=repo_group_name)}" title="${_('Edit')}">Edit</a>
 </div>
 <div class="grid_delete">
    ${h.secure_form(h.route_path('edit_repo_group_advanced_delete', repo_group_name=repo_group_name), request=request)}
        ${h.submit('remove_%s' % repo_group_name,_('Delete'),class_="btn btn-link btn-danger",
        onclick="return confirm('"+_ungettext('Confirm to delete this group: %s with %s repository','Confirm to delete this group: %s with %s repositories',gr_count) % (repo_group_name, gr_count)+"');")}
    ${h.end_form()}
 </div>
</%def>


<%def name="user_actions(user_id, username)">
 <div class="grid_edit">
   <a href="${h.route_path('user_edit',user_id=user_id)}" title="${_('Edit')}">
     <i class="icon-pencil"></i>${_('Edit')}</a>
 </div>
 <div class="grid_delete">
  ${h.secure_form(h.route_path('user_delete', user_id=user_id), request=request)}
    ${h.submit('remove_',_('Delete'),id="remove_user_%s" % user_id, class_="btn btn-link btn-danger",
    onclick="return confirm('"+_('Confirm to delete this user: %s') % username+"');")}
  ${h.end_form()}
 </div>
</%def>

<%def name="user_group_actions(user_group_id, user_group_name)">
 <div class="grid_edit">
    <a href="${h.route_path('edit_user_group', user_group_id=user_group_id)}" title="${_('Edit')}">Edit</a>
 </div>
 <div class="grid_delete">
    ${h.secure_form(h.route_path('user_groups_delete', user_group_id=user_group_id), request=request)}
      ${h.submit('remove_',_('Delete'),id="remove_group_%s" % user_group_id, class_="btn btn-link btn-danger",
      onclick="return confirm('"+_('Confirm to delete this user group: %s') % user_group_name+"');")}
    ${h.end_form()}
 </div>
</%def>


<%def name="user_name(user_id, username)">
    ${h.link_to(h.person(username, 'username_or_name_or_email'), h.route_path('user_edit', user_id=user_id))}
</%def>

<%def name="user_profile(username)">
    ${base.gravatar_with_user(username, 16)}
</%def>

<%def name="user_group_name(user_group_name)">
  <div>
      <i class="icon-group" title="${_('User group')}"></i>
      ${h.link_to_group(user_group_name)}
  </div>
</%def>


## GISTS

<%def name="gist_gravatar(full_contact)">
    <div class="gist_gravatar">
      ${base.gravatar(full_contact, 30)}
    </div>
</%def>

<%def name="gist_access_id(gist_access_id, full_contact)">
    <div>
      <b>
        <a href="${h.route_path('gist_show', gist_id=gist_access_id)}">gist: ${gist_access_id}</a>
      </b>
    </div>
</%def>

<%def name="gist_author(full_contact, created_on, expires)">
    ${base.gravatar_with_user(full_contact, 16)}
</%def>


<%def name="gist_created(created_on)">
    <div class="created">
      ${h.age_component(created_on, time_is_local=True)}
    </div>
</%def>

<%def name="gist_expires(expires)">
    <div class="created">
          %if expires == -1:
            ${_('never')}
          %else:
            ${h.age_component(h.time_to_utcdatetime(expires))}
          %endif
    </div>
</%def>

<%def name="gist_type(gist_type)">
    %if gist_type != 'public':
      <div class="tag">${_('Private')}</div>
    %endif
</%def>

<%def name="gist_description(gist_description)">
  ${gist_description}
</%def>


## PULL REQUESTS GRID RENDERERS

<%def name="pullrequest_target_repo(repo_name)">
    <div class="truncate">
      ${h.link_to(repo_name,h.route_path('repo_summary',repo_name=repo_name))}
    </div>
</%def>
<%def name="pullrequest_status(status)">
    <div class="${'flag_status %s' % status} pull-left"></div>
</%def>

<%def name="pullrequest_title(title, description)">
    ${title} <br/>
    ${h.shorter(description, 40)}
</%def>

<%def name="pullrequest_comments(comments_nr)">
    <i class="icon-comment"></i> ${comments_nr}
</%def>

<%def name="pullrequest_name(pull_request_id, target_repo_name, short=False)">
    <a href="${h.route_path('pullrequest_show',repo_name=target_repo_name,pull_request_id=pull_request_id)}">
      % if short:
        #${pull_request_id}
      % else:
        ${_('Pull request #%(pr_number)s') % {'pr_number': pull_request_id,}}
      % endif
    </a>
</%def>

<%def name="pullrequest_updated_on(updated_on)">
    ${h.age_component(h.time_to_utcdatetime(updated_on))}
</%def>

<%def name="pullrequest_author(full_contact)">
    ${base.gravatar_with_user(full_contact, 16)}
</%def>
