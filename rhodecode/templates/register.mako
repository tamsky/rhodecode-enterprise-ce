## -*- coding: utf-8 -*-
<%inherit file="base/root.mako"/>

<%def name="title()">
    ${_('Create an Account')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>
<style>body{background-color:#eeeeee;}</style>

<div class="loginbox">
    <div class="header">
        <div id="header-inner" class="title">
            <div id="logo">
                <div class="logo-wrapper">
                    <a href="${h.route_path('home')}"><img src="${h.asset('images/rhodecode-logo-white-216x60.png')}" alt="RhodeCode"/></a>
                </div>
                %if c.rhodecode_name:
                <div class="branding"> ${h.branding(c.rhodecode_name)}</div>
                %endif
            </div>
        </div>
    </div>

    <div class="loginwrapper">
        <rhodecode-toast id="notifications"></rhodecode-toast>
        <div class="left-column">
            <img class="sign-in-image" src="${h.asset('images/sign-in.png')}" alt="RhodeCode"/>
        </div>
        <%block name="above_register_button" />
        <div id="register" class="right-column">
            <!-- login -->
            <div class="sign-in-title">
                % if social_auth_provider:
                    <h1>${_('Create an account linked with {}').format(social_auth_provider)}</h1>
                % else:
                    <h1>${_('Create an account')}</h1>
                % endif

                <h4>${h.link_to(_("Go to the login page to sign in with an existing account."), request.route_path('login'))}</h4>
            </div>
            <div class="inner form">
                ${h.form(request.route_path('register'), needs_csrf_token=False)}

                    <label for="username">${_('Username')}:</label>
                    ${h.text('username', defaults.get('username'))}
                    %if 'username' in errors:
                      <span class="error-message">${errors.get('username')}</span>
                      <br />
                    %endif

                    % if social_auth_provider:
                        ## hide password prompts for social auth
                        <div style="display: none">
                    % endif

                    <label for="password">${_('Password')}:</label>
                    ${h.password('password', defaults.get('password'))}
                    %if 'password' in errors:
                      <span class="error-message">${errors.get('password')}</span>
                      <br />
                    %endif

                    <label for="password_confirmation">${_('Re-enter password')}:</label>
                    ${h.password('password_confirmation', defaults.get('password_confirmation'))}
                    %if 'password_confirmation' in errors:
                      <span class="error-message">${errors.get('password_confirmation')}</span>
                      <br />
                    %endif

                    % if social_auth_provider:
                        ## hide password prompts for social auth
                        </div>
                    % endif

                    <label for="firstname">${_('First Name')}:</label>
                    ${h.text('firstname', defaults.get('firstname'))}
                    %if 'firstname' in errors:
                      <span class="error-message">${errors.get('firstname')}</span>
                      <br />
                    %endif

                    <label for="lastname">${_('Last Name')}:</label>
                    ${h.text('lastname', defaults.get('lastname'))}
                    %if 'lastname' in errors:
                      <span class="error-message">${errors.get('lastname')}</span>
                      <br />
                    %endif

                    <label for="email">${_('Email')}:</label>
                    ${h.text('email', defaults.get('email'))}
                    %if 'email' in errors:
                      <span class="error-message">${errors.get('email')}</span>
                      <br />
                    %endif

                    %if captcha_active:
                    <div>
                        <label for="recaptcha">${_('Captcha')}:</label>
                        ${h.hidden('recaptcha_field')}
                        <div id="recaptcha"></div>
                        %if 'recaptcha_field' in errors:
                          <span class="error-message">${errors.get('recaptcha_field')}</span>
                          <br />
                        %endif
                    </div>
                    %endif

                    %if not auto_active:
                        <p class="activation_msg">
                            ${_('Account activation requires admin approval.')}
                        </p>
                    %endif
                    <p class="register_message">
                        ${register_message|n}
                    </p>

                    ${h.submit('sign_up',_('Create Account'),class_="btn sign-in")}
                    <p class="help-block pull-right">
                        RhodeCode ${c.rhodecode_edition}
                    </p>
                ${h.end_form()}
            </div>
            <%block name="below_register_button" />
        </div>
    </div>
</div>


<script type="text/javascript">
 $(document).ready(function(){
    $('#username').focus();
 });
</script>

% if captcha_active:
<script type="text/javascript">
var onloadCallback = function() {
    grecaptcha.render('recaptcha', {
      'sitekey' : "${captcha_public_key}"
    });
};
</script>
<script src="https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit" async defer></script>
% endif

