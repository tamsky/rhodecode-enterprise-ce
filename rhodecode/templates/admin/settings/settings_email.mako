<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Email Configuration')}</h3>
    </div>
    <div class="panel-body">
        <%
         elems = [
            (_('Email prefix'), c.rhodecode_ini.get('email_prefix'), ''),
            (_('Email from'), c.rhodecode_ini.get('app_email_from'), ''),

            (_('SMTP server'), c.rhodecode_ini.get('smtp_server'), ''),
            (_('SMTP username'), c.rhodecode_ini.get('smtp_username'), ''),
            (_('SMTP password'), '%s chars' % len(c.rhodecode_ini.get('smtp_password', '')), ''),
            (_('SMTP port'), c.rhodecode_ini.get('smtp_port'), ''),

            (_('SMTP use TLS'), c.rhodecode_ini.get('smtp_use_tls'), ''),
            (_('SMTP use SSL'), c.rhodecode_ini.get('smtp_use_ssl'), ''),

         ]
        %>
        <dl class="dl-horizontal settings">
        %for dt, dd, tt in elems:
          <dt >${dt}:</dt>
          <dd  title="${h.tooltip(tt)}">${dd}</dd>
        %endfor
        </dl>
        <span class="help-block">
            ${_('You can adjust those settings in [DEFAULT] section of .ini file located at')}: <br/>
            ${c.rhodecode_ini.get('__file__')}
        </span>
    </div>
</div>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Test Email')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.route_path('admin_settings_email_update'), request=request)}

            <div class="field input">
                ${h.text('test_email', size=60, placeholder=_('enter valid email'))}
            </div>
            <div class="field">
                <span class="help-block">
                    ${_('Send an auto-generated email from this server to above email...')}
                </span>
            </div>
            <div class="buttons">
                ${h.submit('send',_('Send'),class_="btn")}
            </div>
        ${h.end_form()}
    </div>
</div>
