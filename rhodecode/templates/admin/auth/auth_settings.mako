## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('Authentication Settings')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${h.link_to(_('Admin'),h.route_path('admin_home'))}
    &raquo;
    ${_('Authentication Plugins')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='admin')}
</%def>

<%def name="main()">

<div class="box">
  <div class="title">
    ${self.breadcrumbs()}
  </div>

  <div class='sidebar-col-wrapper'>

    <div class="sidebar">
        <ul class="nav nav-pills nav-stacked">
          % for item in resource.get_root().get_nav_list():
            <li ${'class=active' if item == resource else ''}>
              <a href="${request.resource_path(item, route_name='auth_home')}">${item.display_name}</a>
            </li>
          % endfor
        </ul>
    </div>

    <div class="main-content-full-width">
      ${h.secure_form(request.resource_path(resource, route_name='auth_home'))}
      <div class="form">

        <div class="panel panel-default">

          <div class="panel-heading">
            <h3 class="panel-title">${_("Enabled and Available Plugins")}</h3>
          </div>

          <div class="fields panel-body">

            <div class="field">
              <div class="label">${_("Enabled Plugins")}</div>
              <div class="textarea text-area editor">
                  ${h.textarea('auth_plugins',cols=23,rows=5,class_="medium")}
              </div>
              <p class="help-block">
              ${_('Add a list of plugins, separated by commas. '
                  'The order of the plugins is also the order in which '
                  'RhodeCode Enterprise will try to authenticate a user.')}
              </p>
            </div>

            <div class="field">
              <div class="label">${_('Available Built-in Plugins')}</div>
              <ul class="auth_plugins">
              %for plugin in available_plugins:
                  <li>
                    <div class="auth_buttons">
                        <span plugin_id="${plugin.get_id()}" class="toggle-plugin btn ${'btn-success' if plugin.get_id() in enabled_plugins else ''}">
                          ${_('enabled') if plugin.get_id() in enabled_plugins else _('disabled')}
                        </span>
                        ${plugin.get_display_name()} (${plugin.get_id()})
                    </div>
                  </li>
              %endfor
              </ul>
            </div>

            <div class="buttons">
              ${h.submit('save',_('Save'),class_="btn")}
            </div>
          </div>
        </div>
      </div>
      ${h.end_form()}
    </div>
  </div>
</div>

<script>
  $('.toggle-plugin').click(function(e){
    var auth_plugins_input = $('#auth_plugins');
    var notEmpty = function(element, index, array) {
      return (element != "");
    };
    var elems = auth_plugins_input.val().split(',').filter(notEmpty);
    var cur_button = e.currentTarget;
    var plugin_id = $(cur_button).attr('plugin_id');
    if($(cur_button).hasClass('btn-success')){
      elems.splice(elems.indexOf(plugin_id), 1);
      auth_plugins_input.val(elems.join(','));
      $(cur_button).removeClass('btn-success');
      cur_button.innerHTML = _gettext('disabled');
    }
    else{
      if(elems.indexOf(plugin_id) == -1){
        elems.push(plugin_id);
      }
      auth_plugins_input.val(elems.join(','));
      $(cur_button).addClass('btn-success');
      cur_button.innerHTML = _gettext('enabled');
    }
  });
</script>
</%def>
