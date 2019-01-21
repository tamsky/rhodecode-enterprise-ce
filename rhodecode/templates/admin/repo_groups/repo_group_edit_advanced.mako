<%namespace name="base" file="/base/base.mako"/>

<%
 elems = [
    (_('Repository Group ID'), c.repo_group.group_id, '', ''),
    (_('Owner'), lambda:base.gravatar_with_user(c.repo_group.user.email), '', ''),
    (_('Created on'), h.format_date(c.repo_group.created_on), '', ''),
    (_('Is Personal Group'), c.repo_group.personal or False, '', ''),

    (_('Total repositories'), c.repo_group.repositories_recursive_count, '', ''),
    (_('Top level repositories'), c.repo_group.repositories.count(), '', c.repo_group.repositories.all()),

    (_('Children groups'), c.repo_group.children.count(), '', c.repo_group.children.all()),
 ]
%>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Repository Group: %s') % c.repo_group.group_name}</h3>
    </div>
    <div class="panel-body">
        ${base.dt_info_panel(elems)}
    </div>

</div>

<div class="panel panel-danger">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Delete repository group')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.route_path('edit_repo_group_advanced_delete', repo_group_name=c.repo_group.group_name), request=request)}
            <table class="display">

                <tr>
                    <td>
                        ${_ungettext('This repository group includes %s children repository group.', 'This repository group includes %s children repository groups.', c.repo_group.children.count()) % c.repo_group.children.count()}
                    </td>
                    <td>
                    </td>
                    <td>
                    </td>
                </tr>
                <tr>
                    <td>
                        ${_ungettext('This repository group includes %s repository.', 'This repository group includes %s repositories.', c.repo_group.repositories_recursive_count) % c.repo_group.repositories_recursive_count}
                    </td>
                    <td>
                    </td>
                    <td>
                    </td>
                </tr>

            </table>
            <div style="margin: 0 0 20px 0" class="fake-space"></div>

            <button class="btn btn-small btn-danger" type="submit"
                onclick="return confirm('${_('Confirm to delete this group: %s') % (c.repo_group.group_name)}');">
                ${_('Delete this repository group')}
            </button>
        ${h.end_form()}
    </div>
</div>


