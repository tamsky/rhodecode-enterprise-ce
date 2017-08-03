## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('%s user group settings') % c.user_group.users_group_name}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${h.link_to(_('Admin'),h.route_path('admin_home'))}
    &raquo;
    ${h.link_to(_('User Groups'),h.url('users_groups'))}
    &raquo;
    ${c.user_group.users_group_name}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='admin')}
</%def>

<%def name="main()">
<div class="box">
  <div class="title">
      ${self.breadcrumbs()}
  </div>

  ##main
  <div class="sidebar-col-wrapper">
    <div class="sidebar">
        <ul class="nav nav-pills nav-stacked">
          <li class="${'active' if c.active=='settings' else ''}"><a href="${h.url('edit_users_group', user_group_id=c.user_group.users_group_id)}">${_('Settings')}</a></li>
          <li class="${'active' if c.active=='perms' else ''}"><a href="${h.url('edit_user_group_perms', user_group_id=c.user_group.users_group_id)}">${_('Permissions')}</a></li>
          <li class="${'active' if c.active=='advanced' else ''}"><a href="${h.url('edit_user_group_advanced', user_group_id=c.user_group.users_group_id)}">${_('Advanced')}</a></li>
          <li class="${'active' if c.active=='global_perms' else ''}"><a href="${h.url('edit_user_group_global_perms', user_group_id=c.user_group.users_group_id)}">${_('Global permissions')}</a></li>
          <li class="${'active' if c.active=='perms_summary' else ''}"><a href="${h.route_path('edit_user_group_perms_summary', user_group_id=c.user_group.users_group_id)}">${_('Permissions summary')}</a></li>
        </ul>
    </div>

    <div class="main-content-full-width">
        <%include file="/admin/user_groups/user_group_edit_${c.active}.mako"/>
    </div>
  </div>
</div>
</%def>
