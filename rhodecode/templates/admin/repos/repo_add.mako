## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('Add repository')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    %if c.rhodecode_user.is_admin:
    ${h.link_to(_('Admin'), h.route_path('admin_home'))}
    &raquo;
    ${h.link_to(_('Repositories'), h.route_path('repos'))}
    %else:
    ${_('Admin')}
    &raquo;
    ${_('Repositories')}
    %endif
    &raquo;
    ${_('Add Repository')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='admin')}
</%def>

<%def name="main()">
    <div class="box">
        <!-- box / title -->
        <div class="title">
            ${self.breadcrumbs()}
        </div>
        <%include file="repo_add_base.mako"/>
    </div>
</%def>
