## -*- coding: utf-8 -*-
<%namespace name="base" file="/base/base.mako"/>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Settings for Repository Group: %s') % c.repo_group.name}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.url('update_repo_group',group_name=c.repo_group.group_name),method='put')}
        <div class="form">
            <!-- fields -->
            <div class="fields">
                <div class="field">
                    <div class="label">
                        <label for="group_name">${_('Group Name')}:</label>
                    </div>
                    <div class="input">
                        ${h.text('group_name',class_='medium')}
                    </div>
                </div>

                <div class="field badged-field">
                    <div class="label">
                        <label for="user">${_('Owner')}:</label>
                    </div>
                    <div class="input">
                        <div class="badge-input-container">
                            <div class="user-badge">
                                ${base.gravatar_with_user(c.repo_group.user.email, show_disabled=not c.repo_group.user.active)}
                            </div>
                            <div class="badge-input-wrap">
                                ${h.text('user', class_="medium", autocomplete="off")}
                            </div>
                        </div>
                        <form:error name="user"/>
                        <p class="help-block">${_('Change owner of this repository group.')}</p>
                    </div>
                </div>

                <div class="field">
                    <div class="label label-textarea">
                        <label for="group_description">${_('Description')}:</label>
                    </div>
                    <div class="textarea text-area editor">
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
                        <label for="group_parent_id">${_('Group parent')}:</label>
                    </div>
                    <div class="select">
                        ${h.select('group_parent_id','',c.repo_groups,class_="medium")}
                    </div>
                </div>
                <div class="field">
                    <div class="label label-checkbox">
                        <label for="enable_locking">${_('Enable Repository Locking')}:</label>
                    </div>
                    <div class="checkboxes">
                        ${h.checkbox('enable_locking',value="True")}
                        <span class="help-block">${_('Repository locking will be enabled on all subgroups and repositories inside this repository group. Pulling from a repository locks it, and it is unlocked by pushing back by the same user.')}</span>
                    </div>
                </div>
                <div class="buttons">
                  ${h.submit('save',_('Save'),class_="btn")}
                  ${h.reset('reset',_('Reset'),class_="btn")}
                </div>
            </div>
        </div>
        ${h.end_form()}
    </div>
</div>
<script>
    $(document).ready(function(){
        $("#group_parent_id").select2({
            'containerCssClass': "drop-menu",
            'dropdownCssClass': "drop-menu-dropdown",
            'dropdownAutoWidth': true
        });
        UsersAutoComplete('user', '${c.rhodecode_user.user_id}');
    })
</script>
