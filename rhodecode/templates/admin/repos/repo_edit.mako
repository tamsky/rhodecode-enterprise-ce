## -*- coding: utf-8 -*-
##
## See also repo_settings.html
##
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('%s repository settings') % c.repo_info.repo_name}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${_('Settings')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>

<%def name="menu_bar_subnav()">
    ${self.repo_menu(active='options')}
</%def>

<%def name="main_content()">
  <%include file="/admin/repos/repo_edit_${c.active}.mako"/>
</%def>


<%def name="main()">
<div class="box">
  <div class="title">
      ${self.repo_page_title(c.rhodecode_db_repo)}
      ${self.breadcrumbs()}
  </div>

  <div class="sidebar-col-wrapper scw-small">
    <div class="sidebar">
        <ul class="nav nav-pills nav-stacked">
          <li class="${'active' if c.active=='settings' else ''}">
              <a href="${h.route_path('edit_repo', repo_name=c.repo_name)}">${_('Settings')}</a>
          </li>
          <li class="${'active' if c.active=='permissions' else ''}">
              <a href="${h.route_path('edit_repo_perms', repo_name=c.repo_name)}">${_('Permissions')}</a>
          </li>
          <li class="${'active' if c.active=='advanced' else ''}">
              <a href="${h.route_path('edit_repo_advanced', repo_name=c.repo_name)}">${_('Advanced')}</a>
          </li>
          <li class="${'active' if c.active=='vcs' else ''}">
              <a href="${h.url('repo_vcs_settings', repo_name=c.repo_name)}">${_('VCS')}</a>
          </li>
          <li class="${'active' if c.active=='fields' else ''}">
              <a href="${h.url('edit_repo_fields', repo_name=c.repo_name)}">${_('Extra Fields')}</a>
          </li>
          <li class="${'active' if c.active=='issuetracker' else ''}">
              <a href="${h.url('repo_settings_issuetracker', repo_name=c.repo_name)}">${_('Issue Tracker')}</a>
          </li>
          <li class="${'active' if c.active=='caches' else ''}">
              <a href="${h.route_path('edit_repo_caches', repo_name=c.repo_name)}">${_('Caches')}</a>
          </li>
          %if c.repo_info.repo_type != 'svn':
          <li class="${'active' if c.active=='remote' else ''}">
              <a href="${h.url('edit_repo_remote', repo_name=c.repo_name)}">${_('Remote')}</a>
          </li>
          %endif
          <li class="${'active' if c.active=='statistics' else ''}">
              <a href="${h.url('edit_repo_statistics', repo_name=c.repo_name)}">${_('Statistics')}</a>
          </li>
          <li class="${'active' if c.active=='integrations' else ''}">
              <a href="${h.route_path('repo_integrations_home', repo_name=c.repo_name)}">${_('Integrations')}</a>
          </li>
          %if c.repo_info.repo_type != 'svn':
          <li class="${'active' if c.active=='reviewers' else ''}">
              <a href="${h.route_path('repo_reviewers', repo_name=c.repo_name)}">${_('Reviewer Rules')}</a>
          </li>
          %endif
          <li class="${'active' if c.active=='maintenance' else ''}">
              <a href="${h.route_path('repo_maintenance', repo_name=c.repo_name)}">${_('Maintenance')}</a>
          </li>
          <li class="${'active' if c.active=='strip' else ''}">
              <a href="${h.route_path('strip', repo_name=c.repo_name)}">${_('Strip')}</a>
          </li>

        </ul>
    </div>

    <div class="main-content-full-width">
      ${self.main_content()}
    </div>

  </div>
</div>

</%def>