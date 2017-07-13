<%namespace name="base" file="/base/base.mako"/>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Repository Permissions')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.route_path('edit_repo_perms', repo_name=c.repo_name), method='POST', request=request)}
        <table id="permissions_manage" class="rctable permissions">
            <tr>
                <th class="td-radio">${_('None')}</th>
                <th class="td-radio">${_('Read')}</th>
                <th class="td-radio">${_('Write')}</th>
                <th class="td-radio">${_('Admin')}</th>
                <th class="td-owner">${_('User/User Group')}</th>
                <th></th>
            </tr>
            ## USERS
            %for _user in c.repo_info.permissions():
                %if getattr(_user, 'admin_row', None) or getattr(_user, 'owner_row', None):
                    <tr class="perm_admin_row">
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.none', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.read', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.write', disabled="disabled")}</td>
                        <td class="td-radio">${h.radio('admin_perm_%s' % _user.user_id,'repository.admin', 'repository.admin', disabled="disabled")}</td>
                        <td class="td-user">
                            ${base.gravatar(_user.email, 16)}
                            ${h.link_to_user(_user.username)}
                            %if getattr(_user, 'admin_row', None):
                                (${_('super admin')})
                            %endif
                            %if getattr(_user, 'owner_row', None):
                                (${_('owner')})
                            %endif
                        </td>
                        <td></td>
                    </tr>
                %elif _user.username == h.DEFAULT_USER and c.repo_info.private:
                    <tr>
                        <td colspan="4">
                            <span class="private_repo_msg">
                            <strong title="${h.tooltip(_user.permission)}">${_('private repository')}</strong>
                            </span>
                        </td>
                        <td class="private_repo_msg">
                            ${base.gravatar(h.DEFAULT_USER_EMAIL, 16)}
                            ${h.DEFAULT_USER} - ${_('only users/user groups explicitly added here will have access')}</td>
                        <td></td>
                    </tr>
                %else:
                    <tr>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'repository.none', checked=_user.permission=='repository.none')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'repository.read', checked=_user.permission=='repository.read')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'repository.write', checked=_user.permission=='repository.write')}</td>
                        <td class="td-radio">${h.radio('u_perm_%s' % _user.user_id,'repository.admin', checked=_user.permission=='repository.admin')}</td>
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
                            <i class="icon-remove"></i> ${_('Revoke')}
                            </span>
                          %endif
                        </td>
                    </tr>
                %endif
            %endfor

            ## USER GROUPS
            %for _user_group in c.repo_info.permission_user_groups():
                <tr>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'repository.none', checked=_user_group.permission=='repository.none')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'repository.read', checked=_user_group.permission=='repository.read')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'repository.write', checked=_user_group.permission=='repository.write')}</td>
                    <td class="td-radio">${h.radio('g_perm_%s' % _user_group.users_group_id,'repository.admin', checked=_user_group.permission=='repository.admin')}</td>
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
                        <span class="btn btn-link btn-danger revoke_perm"
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
        <div class="buttons">
          ${h.submit('save',_('Save'),class_="btn btn-primary")}
          ${h.reset('reset',_('Reset'),class_="btn btn-danger")}
        </div>
        ${h.end_form()}
    </div>
</div>

<script type="text/javascript">
    $('#add_perm').on('click', function(e){
        addNewPermInput($(this), 'repository');
    });
    $('.revoke_perm').on('click', function(e){
        markRevokePermInput($(this), 'repository');
    });
</script>
