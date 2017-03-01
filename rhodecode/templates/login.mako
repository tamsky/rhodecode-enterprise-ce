## -*- coding: utf-8 -*-
<%inherit file="base/root.mako"/>

<%def name="title()">
    ${_('Sign In')}
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
                    <a href="${h.url('home')}"><img src="${h.asset('images/rhodecode-logo-white-216x60.png')}" alt="RhodeCode"/></a>
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
        <%block name="above_login_button" />
        <div id="login" class="right-column">
            <!-- login -->
            <div class="sign-in-title">
                <h1>${_('Sign In')}</h1>
                %if h.HasPermissionAny('hg.admin', 'hg.register.auto_activate', 'hg.register.manual_activate')():
                <h4>${h.link_to(_("Go to the registration page to create a new account."), request.route_path('register'))}</h4>
                %endif
            </div>
            <div class="inner form">
                ${h.form(request.route_path('login', _query={'came_from': came_from}), needs_csrf_token=False)}

                    <label for="username">${_('Username')}:</label>
                    ${h.text('username', class_='focus', value=defaults.get('username'))}
                    %if 'username' in errors:
                    <span class="error-message">${errors.get('username')}</span>
                    <br />
                    %endif

                    <label for="password">${_('Password')}:</label>
                    ${h.password('password', class_='focus')}
                    %if 'password' in errors:
                    <span class="error-message">${errors.get('password')}</span>
                    <br />
                    %endif

                    ${h.checkbox('remember', value=True, checked=defaults.get('remember'))}
                    <label class="checkbox" for="remember">${_('Remember me')}</label>

                    %if h.HasPermissionAny('hg.password_reset.enabled')():
                        <p class="links">
                            ${h.link_to(_('Forgot your password?'), h.route_path('reset_password'), class_='pwd_reset')}
                        </p>
                    %elif h.HasPermissionAny('hg.password_reset.hidden')():
                        <p class="help-block">
                            ${_('Password reset is disabled. Please contact ')}
                            % if c.visual.rhodecode_support_url:
                                <a href="${c.visual.rhodecode_support_url}" target="_blank">${_('Support')}</a>
                                ${_('or')}
                            % endif
                            ${_('an administrator if you need help.')}
                        </p>
                    %endif

                    ${h.submit('sign_in', _('Sign In'), class_="btn sign-in")}

                ${h.end_form()}
                <script type="text/javascript">
                    $(document).ready(function(){
                        $('#username').focus();
                    })
                </script>
            </div>
            <!-- end login -->
            <%block name="below_login_button" />
        </div>
    </div>
</div>
