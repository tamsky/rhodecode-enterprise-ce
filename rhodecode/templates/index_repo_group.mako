## -*- coding: utf-8 -*-
<%inherit file="index_base.mako"/>

<%def name="title()">
    ${_('%s Repository group dashboard') % c.repo_group.group_name}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs()">
    <span class="groups_breadcrumbs">
    ${h.link_to(_(u'Home'),h.url('/'))}
    %if c.repo_group.parent_group:
        &raquo; ${h.link_to(c.repo_group.parent_group.name,h.url('repo_group_home',group_name=c.repo_group.parent_group.group_name))}
    %endif
    &raquo; ${c.repo_group.name}
    </span>
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>
