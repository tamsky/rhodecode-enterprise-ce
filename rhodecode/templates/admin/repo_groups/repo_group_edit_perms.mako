<%namespace name="base" file="/base/base.mako"/>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Repository Group Permissions')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.url('edit_repo_group_perms', group_name=c.repo_group.group_name),method='put')}
        <table id="permissions_manage" class="rctable permissions">
            <tr>
                <th class="td-radio">${_('None')}</th>
                <th class="td-radio">${_('Read')}</th>
                <th class="td-radio">${_('Write')}</th>
                <th class="td-radio">${_('Admin')}</th>
                <th class="td-user">${_('User/User Group')}</th>
                <th></th>
            </tr>
            ## USERS
            %for _user in c.repo_group.permissions():
                %if getattr(_user, 'admin_row', None) or getattr(_user, 'owner_row', None):
                    <tr class="perm_admin_row">
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.none', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.read', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.write', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.admin', 'repository.admin', disabled="disabled")}</td>
                        <td class="td-user">
                            ${base.gravatar(_user.email, 16)}
                            <span class="user">
                                ${h.link_to_user(_user.username)}
                                %if getattr(_user, 'admin_row', None):
                                    (${_('super admin')})
                                %endif
                                %if getattr(_user, 'owner_row', None):
                                    (${_('owner')})
                                %endif
                            </span>
                        </td>
                        <td></td>
                    </tr>
                %else:
                    ##forbid revoking permission from yourself, except if you're an super admin
                    <tr>
                        %if c.rhodecode_user.user_id != _user.user_id or c.rhodecode_user.is_admin:
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.none')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.read')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.write')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.admin')}</td>
                        <td class="td-user">
                            ${base.gravatar(_user.email, 16)}
                            <span class="user">
                                % if _user.username == h.DEFAULT_USER:
                                    ${h.DEFAULT_USER} <span class="user-perm-help-text"> - ${_('permission for all other users')}</span>
                                % else:
                                    ${h.link_to_user(_user.username)}
                                % endif
                            </span>
                        </td>
                        <td class="td-action">
                            %if _user.username != h.DEFAULT_USER:
                                <span  class="btn btn-link btn-danger revoke_perm"
                                  member="${_user.user_id}" member_type="user">
                                <i class="icon-remove"></i> ${_('Revoke')}
                                </span>
                            %endif
                        </td>
                        %else:
                            ## special case for current user permissions, we make sure he cannot take his own permissions
                            <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.none', disabled="disabled")}</td>
                            <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.read', disabled="disabled")}</td>
                            <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.write', disabled="disabled")}</td>
                            <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'group.admin', disabled="disabled")}</td>
                            <td class="td-user">
                                ${base.gravatar(_user.email, 16)}
                                <span class="user">
                                    % if _user.username == h.DEFAULT_USER:
                                        ${h.DEFAULT_USER} <span class="user-perm-help-text"> - ${_('permission for all other users')}</span>
                                    % else:
                                        ${h.link_to_user(_user.username)}
                                    % endif
                                    <span class="user-perm-help-text">(${_('delegated admin')})</span>
                                </span>
                            </td>
                            <td></td>
                        %endif
                    </tr>
                %endif
            %endfor

            ## USER GROUPS
            %for _user_group in c.repo_group.permission_user_groups():
                <tr id="id${id(_user_group.users_group_name)}">
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'group.none')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'group.read')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'group.write')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'group.admin')}</td>
                    <td class="td-componentname">
                        <i class="icon-group" ></i>
                        %if h.HasPermissionAny('hg.admin')():
                         <a href="${h.url('edit_users_group',user_group_id=_user_group.users_group_id)}">
                             ${_user_group.users_group_name}
                         </a>
                        %else:
                         ${_user_group.users_group_name}
                        %endif
                    </td>
                    <td class="td-action">
                        <span  class="btn btn-link btn-danger revoke_perm"
                              member="${_user_group.users_group_id}" member_type="user_group">
                        <i class="icon-remove"></i> ${_('Revoke')}
                        </span>
                    </td>
                </tr>
            %endfor

            <tr class="new_members" id="add_perm_input"></tr>
        </table>
        <div id="add_perm" class="link">
            ${_('Add new')}
        </div>
        <div class="fields">
            <div class="field">
               <div class="label label-radio">
                   ${_('Apply to children')}:
               </div>
               <div class="radios">
                   ${h.radio('recursive', 'none', label=_('None'), checked="checked")}
                   ${h.radio('recursive', 'groups', label=_('Repository Groups'))}
                   ${h.radio('recursive', 'repos', label=_('Repositories'))}
                   ${h.radio('recursive', 'all', label=_('Both'))}
               <span class="help-block">${_('Set or revoke permissions to selected types of children of this group, including non-private repositories and other groups if chosen.')}</span>
               </div>
            </div>
        </div>
        <div class="buttons">
          ${h.submit('save',_('Save'),class_="btn btn-primary")}
          ${h.reset('reset',_('Reset'),class_="btn btn-danger")}
        </div>
        ${h.end_form()}
    </div>
</div>
<script type="text/javascript">
    $('#add_perm').on('click', function(e){
        addNewPermInput($(this), 'group');
    });
    $('.revoke_perm').on('click', function(e){
        markRevokePermInput($(this), 'group');
    })
</script>
