## snippet for displaying permissions overview for users
## usage:
##    <%namespace name="p" file="/base/perms_summary.mako"/>
##    ${p.perms_summary(c.perm_user.permissions)}

<%def name="perms_summary(permissions, show_all=False, actions=True, side_link=None)">
<div id="perms" class="table fields">
  %for section in sorted(permissions.keys()):
  <div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${section.replace("_"," ").capitalize()}</h3>
        % if side_link:
            <div class="pull-right">
                <a href="${side_link}">${_('in JSON format')}</a>
            </div>
        % endif
    </div>
    <div class="panel-body">
      <div class="perms_section_head field">
        <div class="radios">
          %if section != 'global':
              <span class="permissions_boxes">
              <span class="desc">${_('show')}: </span>
              ${h.checkbox('perms_filter_none_%s' % section, 'none', 'checked', class_='perm_filter filter_%s' % section, section=section, perm_type='none')}   <label for="${'perms_filter_none_%s' % section}"><span class="perm_tag none">${_('none')}</span></label>
              ${h.checkbox('perms_filter_read_%s' % section, 'read', 'checked', class_='perm_filter filter_%s' % section, section=section, perm_type='read')}   <label for="${'perms_filter_read_%s' % section}"><span class="perm_tag read">${_('read')}</span></label>
              ${h.checkbox('perms_filter_write_%s' % section, 'write', 'checked', class_='perm_filter filter_%s' % section, section=section, perm_type='write')} <label for="${'perms_filter_write_%s' % section}"> <span class="perm_tag write">${_('write')}</span></label>
              ${h.checkbox('perms_filter_admin_%s' % section, 'admin', 'checked', class_='perm_filter filter_%s' % section, section=section, perm_type='admin')} <label for="${'perms_filter_admin_%s' % section}"><span class="perm_tag admin">${_('admin')}</span></label>
              </span>
          %endif
        </div>
      </div>
      <div class="field">
        %if not permissions[section]:
            <p class="empty_data help-block">${_('No permissions defined')}</p>
        %else:
        <div id='tbl_list_wrap_${section}'>
         <table id="tbl_list_${section}" class="rctable">
          ## global permission box
          %if section == 'global':
            <thead>
                <tr>
                <th colspan="2" class="left">${_('Permission')}</th>
                %if actions:
                <th>${_('Edit Permission')}</th>
                %endif
            </thead>
            <tbody>

            <%
              def get_section_perms(prefix, opts):
                  _selected = []
                  for op in opts:
                      if op.startswith(prefix) and not op.startswith('hg.create.write_on_repogroup'):
                          _selected.append(op)
                  admin = 'hg.admin' in opts
                  _selected_vals = [x.partition(prefix)[-1] for x in _selected]
                  return admin, _selected_vals, _selected
            %>
            <%def name="glob(lbl, val, val_lbl=None, custom_url=None)">
              <tr>
                <td class="td-tags">
                    ${lbl}
                </td>
                <td class="td-tags">
                    %if val[0]:
                      %if not val_lbl:
                          ${h.bool2icon(True)}
                      %else:
                          <span class="perm_tag admin">${val_lbl}.admin</span>
                      %endif
                    %else:
                      %if not val_lbl:
                          ${h.bool2icon({'false': False,
                                         'true': True,
                                         'none': False,
                                         'repository': True}.get(val[1][0] if 0 < len(val[1]) else 'false'))}
                      %else:
                          <span class="perm_tag ${val[1][0]}">${val_lbl}.${val[1][0]}</span>
                      %endif
                    %endif
                </td>
                %if actions:
                <td class="td-action">
                     <a href="${custom_url or h.route_path('admin_permissions_global')}">${_('edit')}</a>
                </td>
                %endif
              </tr>
            </%def>

           ${glob(_('Super admin'), get_section_perms('hg.admin', permissions[section]))}

           ${glob(_('Repository default permission'), get_section_perms('repository.', permissions[section]), 'repository', h.route_path('admin_permissions_object'))}
           ${glob(_('Repository group default permission'), get_section_perms('group.', permissions[section]), 'group', h.route_path('admin_permissions_object'))}
           ${glob(_('User group default permission'), get_section_perms('usergroup.', permissions[section]), 'usergroup', h.route_path('admin_permissions_object'))}

           ${glob(_('Create repositories'), get_section_perms('hg.create.', permissions[section]), custom_url=h.route_path('admin_permissions_global'))}
           ${glob(_('Fork repositories'), get_section_perms('hg.fork.', permissions[section]), custom_url=h.route_path('admin_permissions_global'))}
           ${glob(_('Create repository groups'), get_section_perms('hg.repogroup.create.', permissions[section]), custom_url=h.route_path('admin_permissions_global'))}
           ${glob(_('Create user groups'), get_section_perms('hg.usergroup.create.', permissions[section]), custom_url=h.route_path('admin_permissions_global'))}


           </tbody>
          %else:
           ## none/read/write/admin permissions on groups/repos etc
            <thead>
                <tr>
                <th>${_('Name')}</th>
                <th>${_('Permission')}</th>
                %if actions:
                <th>${_('Edit Permission')}</th>
                %endif
            </thead>
            <tbody class="section_${section}">
            <%
                def sorter(permissions):
                    def custom_sorter(item):
                       ## read/write/admin
                       section = item[1].split('.')[-1]
                       section_importance = {'none': u'0',
                                             'read': u'1',
                                             'write':u'2',
                                             'admin':u'3'}.get(section)
                       ## sort by group importance+name
                       return section_importance+item[0]
                    return sorted(permissions, key=custom_sorter)
            %>
            %for k, section_perm in sorter(permissions[section].items()):
                %if section_perm.split('.')[-1] != 'none' or show_all:
                <tr class="perm_row ${'%s_%s' % (section, section_perm.split('.')[-1])}">
                    <td class="td-componentname">
                        %if section == 'repositories':
                            <a href="${h.route_path('repo_summary',repo_name=k)}">${k}</a>
                        %elif section == 'repositories_groups':
                            <a href="${h.route_path('repo_group_home', repo_group_name=k)}">${k}</a>
                        %elif section == 'user_groups':
                            ##<a href="${h.url('edit_users_group',user_group_id=k)}">${k}</a>
                            ${k}
                        %endif
                    </td>
                    <td class="td-tags">
                      %if hasattr(permissions[section], 'perm_origin_stack'):
                         %for i, (perm, origin) in enumerate(reversed(permissions[section].perm_origin_stack[k])):
                         <span class="${i > 0 and 'perm_overriden' or ''} perm_tag ${perm.split('.')[-1]}">
                          ${perm} (${origin})
                        </span>
                         %endfor
                      %else:
                         <span class="perm_tag ${section_perm.split('.')[-1]}">${section_perm}</span>
                      %endif
                    </td>
                    %if actions:
                    <td class="td-action">
                        %if section == 'repositories':
                            <a href="${h.route_path('edit_repo_perms',repo_name=k,_anchor='permissions_manage')}">${_('edit')}</a>
                        %elif section == 'repositories_groups':
                            <a href="${h.url('edit_repo_group_perms',group_name=k,anchor='permissions_manage')}">${_('edit')}</a>
                        %elif section == 'user_groups':
                            ##<a href="${h.url('edit_users_group',user_group_id=k)}">${_('edit')}</a>
                        %endif
                    </td>
                    %endif
                </tr>
                %endif
            %endfor

            <tr id="empty_${section}" class="noborder" style="display:none;">
              <td colspan="6">${_('No permission defined')}</td>
            </tr>

            </tbody>
          %endif
         </table>
        </div>
        %endif
      </div>
    </div>
  </div>
  %endfor
</div>

<script>
    $(document).ready(function(){
        var show_empty = function(section){
            var visible = $('.section_{0} tr.perm_row:visible'.format(section)).length;
            if(visible == 0){
                $('#empty_{0}'.format(section)).show();
            }
            else{
                $('#empty_{0}'.format(section)).hide();
            }
        };
        $('.perm_filter').on('change', function(e){
            var self = this;
            var section = $(this).attr('section');

            var opts = {};
            var elems = $('.filter_' + section).each(function(el){
                var perm_type = $(this).attr('perm_type');
                var checked = this.checked;
                opts[perm_type] = checked;
                if(checked){
                    $('.'+section+'_'+perm_type).show();
                }
                else{
                    $('.'+section+'_'+perm_type).hide();
                }
            });
            show_empty(section);
        })
    })
</script>
</%def>
