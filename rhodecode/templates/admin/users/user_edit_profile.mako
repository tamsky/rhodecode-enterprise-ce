<%namespace name="base" file="/base/base.mako"/>

<div class="panel panel-default user-profile">
    <div class="panel-heading">
        <h3 class="panel-title">${_('User Profile')}</h3>
    </div>
    <div class="panel-body">
        <div class="user-profile-content">
        ${h.secure_form(h.route_path('user_update', user_id=c.user.user_id), class_='form', request=request)}
        <% readonly = None %>
        <% disabled = "" %>
        %if c.extern_type != 'rhodecode':
            <% readonly = "readonly" %>
            <% disabled = " disabled" %>
            <div class="infoform">
              <div class="fields">
                <p>${_('This user was created from external source (%s). Editing some of the settings is limited.' % c.extern_type)}</p>
              </div>
            </div>
        %endif
        <div class="form">
          <div class="fields">
            <div class="field">
                <div class="label photo">
                    ${_('Photo')}:
                </div>
                <div class="input profile">
                    %if c.visual.use_gravatar:
                        ${base.gravatar(c.user.email, 100)}
                        <p class="help-block">${_('Change the avatar at')} <a href="http://gravatar.com">gravatar.com</a>.</p>
                    %else:
                        ${base.gravatar(c.user.email, 100)}
                    %endif
                </div>
            </div>
            <div class="field">
               <div class="label">
                    ${_('Username')}:
               </div>
               <div class="input">
                    ${h.text('username', class_='%s medium' % disabled, readonly=readonly)}
               </div>
            </div>
            <div class="field">
               <div class="label">
                   <label for="name">${_('First Name')}:</label>
               </div>
               <div class="input">
                   ${h.text('firstname', class_="medium")}
               </div>
            </div>
    
            <div class="field">
               <div class="label">
                   <label for="lastname">${_('Last Name')}:</label>
               </div>
               <div class="input">
                   ${h.text('lastname', class_="medium")}
               </div>
            </div>
    
            <div class="field">
               <div class="label">
                   <label for="email">${_('Email')}:</label>
               </div>
               <div class="input">
                   ## we should be able to edit email !
                   ${h.text('email', class_="medium")}
               </div>
            </div>
            <div class="field">
               <div class="label">
                    ${_('New Password')}:
               </div>
               <div class="input">
                    ${h.password('new_password',class_='%s medium' % disabled,autocomplete="off",readonly=readonly)}
                </div>
            </div>
            <div class="field">
               <div class="label">
                    ${_('New Password Confirmation')}:
               </div>
               <div class="input">
                    ${h.password('password_confirmation',class_="%s medium" % disabled,autocomplete="off",readonly=readonly)}
                </div>
            </div>
            <div class="field">
               <div class="label-text">
                    ${_('Active')}:
               </div>
               <div class="input user-checkbox">
                    ${h.checkbox('active',value=True)}
                </div>
            </div>
            <div class="field">
               <div class="label-text">
                    ${_('Super Admin')}:
               </div>
               <div class="input user-checkbox">
                    ${h.checkbox('admin',value=True)}
                </div>
            </div>
            <div class="field">
               <div class="label-text">
                    ${_('Authentication type')}:
               </div>
               <div class="input">
                    <p>${c.extern_type}</p>
                    ${h.hidden('extern_type', readonly="readonly")}
                    <p class="help-block">${_('User was created using an external source. He is bound to authentication using this method.')}</p>
                </div>
            </div>
            <div class="field">
               <div class="label-text">
                    ${_('Name in Source of Record')}:
               </div>
               <div class="input">
                    <p>${c.extern_name}</p>
                    ${h.hidden('extern_name', readonly="readonly")}
                </div>
            </div>
            <div class="field">
               <div class="label">
                    ${_('Language')}:
               </div>
               <div class="input">
                    ## allowed_languages is defined in the users.py
                    ## c.language comes from base.py as a default language
                    ${h.select('language', c.language, c.allowed_languages)}
                    <p class="help-block">${h.literal(_('User interface language. Help translate %(rc_link)s into your language.') % {'rc_link': h.link_to('RhodeCode Enterprise', h.route_url('rhodecode_translations'))})}</p>
                </div>
            </div>
            <div class="buttons">
              ${h.submit('save', _('Save'), class_="btn")}
              ${h.reset('reset', _('Reset'), class_="btn")}
            </div>
          </div>
        </div>
        ${h.end_form()}
        </div>
    </div>
</div>

<script>
    $('#language').select2({
        'containerCssClass': "drop-menu",
        'dropdownCssClass': "drop-menu-dropdown",
        'dropdownAutoWidth': true
    });
</script>
