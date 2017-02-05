<%namespace name="base" file="/base/base.mako"/>

<%
 elems = [
    (_('Owner'), lambda:base.gravatar_with_user(c.user_group.user.email), '', ''),
    (_('Created on'), h.format_date(c.user_group.created_on), '', '',),

    (_('Members'), len(c.group_members_obj),'', [x for x in c.group_members_obj]),
    (_('Assigned to repositories'), len(c.group_to_repos),'', [x for x in c.group_to_repos]),
    (_('Assigned to repo groups'), len(c.group_to_repo_groups), '', [x for x in c.group_to_repo_groups]),

 ]
%>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('User Group: %s') % c.user_group.users_group_name}</h3>
    </div>
    <div class="panel-body">
        ${base.dt_info_panel(elems)}
    </div>
</div>

<div class="panel panel-danger">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Delete User Group')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.url('delete_users_group', user_group_id=c.user_group.users_group_id),method='delete')}
            ${h.hidden('force', 1)}
            <button class="btn btn-small btn-danger" type="submit"
                    onclick="return confirm('${_('Confirm to delete user group `%(ugroup)s` with all permission assignments') % {'ugroup': c.user_group.users_group_name}}');">
                <i class="icon-remove-sign"></i>
                ${_('Delete This User Group')}
            </button>
        ${h.end_form()}
    </div>
</div>
