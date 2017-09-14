## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('Add repository group')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${h.link_to(_('Admin'),h.route_path('admin_home'))}
    &raquo;
    ${h.link_to(_('Repository groups'),h.url('repo_groups'))}
    &raquo;
    ${_('Add Repository Group')}
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
    ${h.secure_form(h.url('repo_groups'), method='post')}
    <div class="form">
        <!-- fields -->
        <div class="fields">
             <div class="field">
                <div class="label">
                    <label for="group_name">${_('Group Name')}:</label>
                </div>
                <div class="input">
                    ${h.text('group_name', class_="medium")}
                </div>
             </div>

            <div class="field">
                <div class="label">
                    <label for="group_description">${_('Description')}:</label>
                </div>
                <div class="textarea editor">
                    ${h.textarea('group_description',cols=23,rows=5,class_="medium")}
                    <% metatags_url = h.literal('''<a href="#metatagsShow" onclick="$('#meta-tags-desc').toggle();return false">meta-tags</a>''') %>
                    <span class="help-block">${_('Plain text format with support of {metatags}').format(metatags=metatags_url)|n}</span>
                    <span id="meta-tags-desc" style="display: none">
                        <%namespace name="dt" file="/data_table/_dt_elements.mako"/>
                        ${dt.metatags_help()}
                    </span>
                </div>
            </div>

            <div class="field">
                 <div class="label">
                     <label for="group_parent_id">${_('Group Parent')}:</label>
                 </div>
                 <div class="select">
                     ${h.select('group_parent_id',request.GET.get('parent_group'),c.repo_groups,class_="medium")}
                 </div>
            </div>

            <div id="copy_perms" class="field">
                <div class="label label-checkbox">
                    <label for="group_copy_permissions">${_('Copy Parent Group Permissions')}:</label>
                </div>
                <div class="checkboxes">
                    ${h.checkbox('group_copy_permissions', value="True", checked="checked")}
                    <span class="help-block">${_('Copy permission settings from parent repository group.')}</span>
                </div>
            </div>

            <div class="buttons">
              ${h.submit('save',_('Save'),class_="btn")}
            </div>
        </div>
    </div>
    ${h.end_form()}
</div>
<script>
    $(document).ready(function(){
        var setCopyPermsOption = function(group_val){
            if(group_val != "-1"){
                $('#copy_perms').show()
            }
            else{
                $('#copy_perms').hide();
            }
        }
        $("#group_parent_id").select2({
            'containerCssClass': "drop-menu",
            'dropdownCssClass': "drop-menu-dropdown",
            'dropdownAutoWidth': true
        });
        setCopyPermsOption($('#group_parent_id').val())
        $("#group_parent_id").on("change", function(e) {
            setCopyPermsOption(e.val)
        })
        $('#group_name').focus();
    })
</script>
</%def>
