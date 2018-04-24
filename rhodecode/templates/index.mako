## -*- coding: utf-8 -*-
<%inherit file="index_base.mako"/>

<%def name="title()">
    ${_('Dashboard')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs()"></%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>
