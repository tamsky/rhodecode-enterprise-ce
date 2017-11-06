<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('System Wide Application Permissions')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.route_path('admin_permissions_application_update'), request=request)}
            <div class="form">
                <!-- fields -->
                <div class="fields">
                    <div class="field">
                        <div class="label label-checkbox">
                            <label for="anonymous">${_('Anonymous Access')}:</label>
                        </div>
                        <div class="checkboxes">
                            <div class="checkbox">
                                ${h.checkbox('anonymous',True)} Allow Anonymous Access
                            </div>
                             <span class="help-block">${h.literal(_('Allow access to RhodeCode Enterprise without requiring users to login. Anonymous users get the %s permission settings.' % (h.link_to('"default user"',h.route_path('admin_permissions_object')))))}</span>
                        </div>
                    </div>

                    <div class="field">
                        <div class="label label-select">
                            <label for="default_register">${_('Registration')}:</label>
                        </div>
                        <div class="select">
                            ${h.select('default_register','',c.register_choices)}
                        </div>
                    </div>

                    <div class="field">
                        <div class="label label-select">
                            <label for="default_password_reset">${_('Password Reset')}:</label>
                        </div>
                        <div class="select">
                            ${h.select('default_password_reset','',c.password_reset_choices)}
                        </div>
                    </div>

                    <div class="field">
                        <div class="label label-textarea">
                            <label for="default_register_message">${_('Registration Page Message')}:</label>
                        </div>
                        <div class="textarea text-area editor" >
                            ${h.textarea('default_register_message', class_="medium", )}
                            <span class="help-block">${_('Custom message to be displayed on the registration page. HTML syntax is supported.')}</span>
                        </div>
                     </div>

                     <div class="field">
                        <div class="label">
                            <label for="default_extern_activate">${_('External Authentication Account Activation')}:</label>
                        </div>
                        <div class="select">
                            ${h.select('default_extern_activate','',c.extern_activate_choices)}
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
        var select2Options = {
            containerCssClass: 'drop-menu',
            dropdownCssClass: 'drop-menu-dropdown',
            dropdownAutoWidth: true,
            minimumResultsForSearch: -1
        };

        $("#default_register").select2(select2Options);
        $("#default_password_reset").select2(select2Options);
        $("#default_extern_activate").select2(select2Options);
    });
</script>
