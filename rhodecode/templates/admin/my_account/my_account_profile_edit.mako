<%namespace name="base" file="/base/base.mako"/>
<div class="panel panel-default user-profile">
    <div class="panel-heading">
        <h3 class="panel-title">${_('My Profile')}</h3>
        <a href="${h.route_path('my_account_profile')}" class="panel-edit">Close</a>
    </div>

    <div class="panel-body">
    ${h.secure_form(url('my_account'), method='post', class_='form')}
    <% readonly = None %>
    <% disabled = "" %>

    % if c.extern_type != 'rhodecode':
        <% readonly = "readonly" %>
        <% disabled = "disabled" %>
        <div class="infoform">
          <div class="fields">
            <p>${_('Your user account details are managed by an external source. Details cannot be managed here.')}
               <br/>${_('Source type')}: <strong>${c.extern_type}</strong>
            </p>

            <div class="field">
               <div class="label">
                   <label for="username">${_('Username')}:</label>
               </div>
               <div class="input">
                 ${h.text('username', class_='input-valuedisplay', readonly=readonly)}
               </div>
            </div>
    
            <div class="field">
               <div class="label">
                   <label for="name">${_('First Name')}:</label>
               </div>
               <div class="input">
                   ${h.text('firstname', class_='input-valuedisplay', readonly=readonly)}
               </div>
            </div>
    
            <div class="field">
               <div class="label">
                   <label for="lastname">${_('Last Name')}:</label>
               </div>
               <div class="input-valuedisplay">
                   ${h.text('lastname', class_='input-valuedisplay', readonly=readonly)}
               </div>
            </div>
          </div>
        </div>
    % else:
        <div class="form">
          <div class="fields">
            <div class="field">
                <div class="label photo">
                    ${_('Photo')}:
                </div>
                <div class="input profile">
                    %if c.visual.use_gravatar:
                        ${base.gravatar(c.user.email, 100)}
                        <p class="help-block">${_('Change your avatar at')} <a href="http://gravatar.com">gravatar.com</a>.</p>
                    %else:
                        ${base.gravatar(c.user.email, 20)}
                        ${_('Avatars are disabled')}
                    %endif
                </div>
            </div>
            <div class="field">
               <div class="label">
                   <label for="username">${_('Username')}:</label>
               </div>
               <div class="input">
                 ${h.text('username', class_='medium%s' % disabled, readonly=readonly)}
                 ${h.hidden('extern_name', c.extern_name)}
                 ${h.hidden('extern_type', c.extern_type)}
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
    
            <div class="buttons">
              ${h.submit('save', _('Save'), class_="btn")}
              ${h.reset('reset', _('Reset'), class_="btn")}
            </div>
          </div>
        </div>
    % endif
    </div>
</div>