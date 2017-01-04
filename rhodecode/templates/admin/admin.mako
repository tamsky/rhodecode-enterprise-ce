## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('Admin journal')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${h.form(None, id_="filter_form", method="get")}
        <input class="q_filter_box ${'' if c.search_term else 'initial'}" id="j_filter" size="15" type="text" name="filter" value="${c.search_term or ''}" placeholder="${_('journal filter...')}"/>
        <input type='submit' value="${_('filter')}" class="btn" />
        ${_('Admin journal')} - ${ungettext('%s entry', '%s entries', c.users_log.item_count) % (c.users_log.item_count)}
    ${h.end_form()}
    <p class="tooltip filterexample" title="${h.tooltip(h.journal_filter_help())}">${_('Example Queries')}</p>
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
    <!-- end box / title -->
    <div class="table">
        <div id="user_log">
            ${c.log_data}
        </div>
    </div>
</div>

<script>
$('#j_filter').autoGrowInput();
</script>
</%def>
