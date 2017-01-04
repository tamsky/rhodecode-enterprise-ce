<%namespace name="base" file="/base/base.mako"/>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('User Group Permissions')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(url('edit_user_group_perms', user_group_id=c.user_group.users_group_id),method='put')}
        <table id="permissions_manage" class="rctable permissions">
            <tr>
                <th class="td-radio">${_('None')}</th>
                <th class="td-radio">${_('Read')}</th>
                <th class="td-radio">${_('Write')}</th>
                <th class="td-radio">${_('Admin')}</th>
                <th>${_('User/User Group')}</th>
                <th></th>
            </tr>
            ## USERS
            %for _user in c.user_group.permissions():
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
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.none')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.read')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.write')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.admin')}</td>
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
                            <span class="btn btn-link btn-danger revoke_perm"
                                  member="${_user.user_id}" member_type="user">
                            <i class="icon-remove"></i> ${_('revoke')}
                            </span>
                          %endif
                        </td>
                        %else:
                        ## special case for current user permissions, we make sure he cannot take his own permissions
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.none', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.read', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.write', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'usergroup.admin', disabled="disabled")}</td>
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
            %for _user_group in c.user_group.permission_user_groups():
                <tr>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'usergroup.none')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'usergroup.read')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'usergroup.write')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'usergroup.admin')}</td>
                    <td class="td-user">
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
                        <span class="btn btn-link btn-danger revoke_perm"
                              member="${_user_group.users_group_id}" member_type="user_group">
                        <i class="icon-remove"></i> ${_('revoke')}
                        </span>
                    </td>
                </tr>
            %endfor
            <tr class="new_members" id="add_perm_input"></tr>
        </table>
        <div id="add_perm" class="link">
            ${_('Add new')}
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
        addNewPermInput($(this), 'usergroup');
    });
    $('.revoke_perm').on('click', function(e){
        markRevokePermInput($(this), 'usergroup');
    });
</script>
