## snippet for displaying default permission box
## usage:
##    <%namespace name="dpb" file="/base/default_perms_box.mako"/>
##    ${dpb.default_perms_box(<url_to_form>)}
##    ${dpb.default_perms_radios()}

<%def name="default_perms_radios(global_permissions_template = False, suffix='', **kwargs)">
<div class="main-content-full-width">
  <div class="panel panel-default">

    ## displayed according to checkbox selection
    <div class="panel-heading">
      %if not global_permissions_template:
        <h3 class="inherit_overlay_default panel-title">${_('Inherited Permissions')}</h3>
        <h3 class="inherit_overlay panel-title">${_('Custom Permissions')}</h3>
      %else:
        <h3 class="panel-title">${_('Default Global Permissions')}</h3>
      %endif
    </div>

    <div class="panel-body">
      %if global_permissions_template:
        <p>${_('The following options configure the default permissions each user or group will inherit. You can override these permissions for each individual user or user group using individual permissions settings.')}</p>
      %endif
        <div class="field">
           <div class="label">
               <label for="default_repo_create${suffix}">${_('Repository Creation')}:</label>
           </div>
           <div class="radios">
               ${h.radio('default_repo_create' + suffix, c.repo_create_choices[1][0], label=c.repo_create_choices[1][1], **kwargs)}
               ${h.radio('default_repo_create' + suffix, c.repo_create_choices[0][0], label=c.repo_create_choices[0][1], **kwargs)}
               <span class="help-block">${_('Permission to create root level repositories. When disabled, users can still create repositories inside their own repository groups.')}</span>
           </div>
        </div>
        <div class="field">
           <div class="label">
               <label for="default_repo_create_on_write${suffix}">${_('Repository Creation With Group Write Access')}:</label>
           </div>
           <div class="radios">
               ${h.radio('default_repo_create_on_write' + suffix, c.repo_create_on_write_choices[1][0], label=c.repo_create_on_write_choices[1][1], **kwargs)}
               ${h.radio('default_repo_create_on_write' + suffix, c.repo_create_on_write_choices[0][0], label=c.repo_create_on_write_choices[0][1], **kwargs)}
               <span class="help-block">${_('Write permission given on a repository group will allow creating repositories inside that group.')}</span>
           </div>
        </div>
        <div class="field">
           <div class="label">
               <label for="default_fork_create${suffix}">${_('Repository Forking')}:</label>
           </div>
           <div class="radios">
               ${h.radio('default_fork_create' + suffix, c.fork_choices[1][0], label=c.fork_choices[1][1], **kwargs)}
               ${h.radio('default_fork_create' + suffix, c.fork_choices[0][0], label=c.fork_choices[0][1], **kwargs)}
               <span class="help-block">${_('Permission to create root level repository forks. When disabled, users can still fork repositories inside their own repository groups.')}</span>
           </div>
        </div>
        <div class="field">
           <div class="label">
               <label for="default_repo_group_create${suffix}">${_('Repository Group Creation')}:</label>
           </div>
           <div class="radios">
               ${h.radio('default_repo_group_create' + suffix, c.repo_group_create_choices[1][0], label=c.repo_group_create_choices[1][1], **kwargs)}
               ${h.radio('default_repo_group_create' + suffix, c.repo_group_create_choices[0][0], label=c.repo_group_create_choices[0][1], **kwargs)}
               <span class="help-block">${_('Permission to create root level repository groups. When disabled, repository group admins can still create repository subgroups within their repository groups.')}</span>
           </div>
        </div>
        <div class="field">
           <div class="label">
               <label for="default_user_group_create${suffix}">${_('User Group Creation')}:</label>
           </div>
           <div class="radios">
               ${h.radio('default_user_group_create' + suffix, c.user_group_create_choices[1][0], label=c.user_group_create_choices[1][1], **kwargs)}
               ${h.radio('default_user_group_create' + suffix, c.user_group_create_choices[0][0], label=c.user_group_create_choices[0][1], **kwargs)}
               <span class="help-block">${_('Permission to allow user group creation.')}</span>
           </div>
        </div>

        <div class="field">
           <div class="label">
               <label for="default_inherit_default_permissions${suffix}">${_('Inherit Permissions From The Default User')}:</label>
           </div>
           <div class="radios">
               ${h.radio('default_inherit_default_permissions' + suffix, c.inherit_default_permission_choices[1][0], label=c.inherit_default_permission_choices[1][1], **kwargs)}
               ${h.radio('default_inherit_default_permissions' + suffix, c.inherit_default_permission_choices[0][0], label=c.inherit_default_permission_choices[0][1], **kwargs)}
               <span class="help-block">${_('Inherit default permissions from the default user. Turn off this option to force explicit permissions for users, even if they are more restrictive than the default user permissions.')}</span>
           </div>
        </div>

        <div class="buttons">
         ${h.submit('save',_('Save'),class_="btn")}
         ${h.reset('reset',_('Reset'),class_="btn")}
        </div>
    </div>
  </div>
</div>
</%def>

<%def name="default_perms_box(form_url)">
  ${h.secure_form(form_url, request=request)}
    <div class="form">
      <div class="fields">
        <div class="field panel panel-default panel-body">
          <div class="label label-checkbox">
              <label for="inherit_default_permissions">${_('Inherit from default settings')}:</label>
          </div>
          <div class="checkboxes">
              ${h.checkbox('inherit_default_permissions',value=True)}
              <span class="help-block">
              ${h.literal(_('Select to inherit permissions from %s permissions settings, '
                            'including default IP address whitelist and inheritance of \npermission by members of user groups.')
                          % h.link_to('default user', h.route_path('admin_permissions_global')))}
              </span>
          </div>
        </div>
  
        ## INHERITED permissions == the user permissions in admin
        ## if inherit checkbox is set this is displayed in non-edit mode
        <div class="inherit_overlay_default">
            ${default_perms_radios(global_permissions_template = False, suffix='_inherited', disabled="disabled")}
        </div>
  
        ## CUSTOM permissions
        <div class="inherit_overlay">
            ${default_perms_radios(global_permissions_template = False)}
        </div>
      </div>
    </div>
  ${h.end_form()}

        
## JS
<script>
var show_custom_perms = function(inherit_default){
    if(inherit_default) {
        $('.inherit_overlay_default').show();
        $('.inherit_overlay').hide();
    }
    else {
        $('.inherit_overlay').show();
        $('.inherit_overlay_default').hide();
    }
};
$(document).ready(function(e){
    var inherit_checkbox = $('#inherit_default_permissions');
    var defaults = inherit_checkbox.prop('checked');
    show_custom_perms(defaults);
    inherit_checkbox.on('change', function(){
        if($(this).prop('checked')){
           show_custom_perms(true);
        }
        else{
           show_custom_perms(false);
        }
    })
})
</script>

</%def>
