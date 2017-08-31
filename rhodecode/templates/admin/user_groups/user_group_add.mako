## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('Add user group')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>
<%def name="breadcrumbs_links()">
    ${h.link_to(_('Admin'),h.route_path('admin_home'))}
    &raquo;
    ${h.link_to(_('User groups'),h.route_path('user_groups'))}
    &raquo;
    ${_('Add User Group')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='admin')}
</%def>

<%def name="main()">
<div class="box main-content">
    <!-- box / title -->
    <div class="title">
        ${self.breadcrumbs()}
    </div>
    <!-- end box / title -->
    ${h.secure_form(h.route_path('user_groups_create'), method='POST', request=request)}
    <div class="form">
        <!-- fields -->
        <div class="fields">
             <div class="field">
                <div class="label">
                    <label for="users_group_name">${_('Group name')}:</label>
                </div>
                <div class="input">
                    ${h.text('users_group_name', class_='medium')}
                </div>
             </div>
            <div class="field">
                <div class="label">
                    <label for="user_group_description">${_('Description')}:</label>
                </div>
                <div class="textarea editor">
                    ${h.textarea('user_group_description')}
                    <span class="help-block">${_('Short, optional description for this user group.')}</span>
                </div>
             </div>
             <div class="field">
                <div class="label">
                    <label for="users_group_active">${_('Active')}:</label>
                </div>
                <div class="checkboxes">
                    ${h.checkbox('users_group_active',value=True, checked='checked')}
                </div>
             </div>

            <div class="buttons">
              ${h.submit('save',_('Save'),class_="btn")}
            </div>
        </div>
    </div>
    ${h.end_form()}
</div>
</%def>

<script>
    $(document).ready(function(){
        $('#users_group_name').focus();
    })
</script>
