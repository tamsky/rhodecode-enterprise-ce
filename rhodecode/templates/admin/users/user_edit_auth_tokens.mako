<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Authentication Access Tokens')}</h3>
    </div>
    <div class="panel-body">
        <div class="apikeys_wrap">
          <table class="rctable auth_tokens">
            <tr>
                <td class="truncate-wrap td-authtoken"><div class="user_auth_tokens truncate autoexpand"><code>${c.user.api_key}</code></div></td>
                <td class="td-tags">
                    <span class="tag disabled">${_('Built-in')}</span>
                </td>
                <td class="td-tags">
                    % for token in c.user.builtin_token_roles:
                    <span class="tag disabled">
                        ${token}
                    </span>
                    % endfor
                </td>
                <td class="td-exp">${_('expires')}: ${_('never')}</td>
                <td class="td-action">
                    ${h.secure_form(url('edit_user_auth_tokens', user_id=c.user.user_id),method='delete')}
                        ${h.hidden('del_auth_token',c.user.api_key)}
                        ${h.hidden('del_auth_token_builtin',1)}
                        <button class="btn btn-link btn-danger" type="submit"
                                onclick="return confirm('${_('Confirm to reset this auth token: %s') % c.user.api_key}');">
                            ${_('Reset')}
                        </button>
                    ${h.end_form()}
                </td>
            </tr>
            %if c.user_auth_tokens:
                %for auth_token in c.user_auth_tokens:
                  <tr class="${'expired' if auth_token.expired else ''}">
                    <td class="truncate-wrap td-authtoken"><div class="user_auth_tokens truncate autoexpand"><code>${auth_token.api_key}</code></div></td>
                    <td class="td-wrap">${auth_token.description}</td>
                    <td class="td-tags">
                        <span class="tag">${auth_token.role_humanized}</span>
                    </td>
                    <td class="td-exp">
                         %if auth_token.expires == -1:
                          ${_('expires')}: ${_('never')}
                         %else:
                            %if auth_token.expired:
                                ${_('expired')}: ${h.age_component(h.time_to_utcdatetime(auth_token.expires))}
                            %else:
                                ${_('expires')}: ${h.age_component(h.time_to_utcdatetime(auth_token.expires))}
                            %endif
                         %endif
                    </td>
                    <td>
                        ${h.secure_form(url('edit_user_auth_tokens', user_id=c.user.user_id),method='delete')}
                            ${h.hidden('del_auth_token',auth_token.api_key)}
                            <button class="btn btn-link btn-danger" type="submit"
                                    onclick="return confirm('${_('Confirm to remove this auth token: %s') % auth_token.api_key}');">
                                ${_('Delete')}
                            </button>
                        ${h.end_form()}
                    </td>
                  </tr>
                %endfor
            %else:
            <tr><td><div class="ip">${_('No additional auth tokens specified')}</div></td></tr>
            %endif
          </table>
        </div>

        <div class="user_auth_tokens">
            ${h.secure_form(url('edit_user_auth_tokens', user_id=c.user.user_id), method='put')}
            <div class="form form-vertical">
                <!-- fields -->
                <div class="fields">
                     <div class="field">
                        <div class="label">
                            <label for="new_email">${_('New auth token')}:</label>
                        </div>
                        <div class="input">
                            ${h.text('description', class_='medium', placeholder=_('Description'))}
                            ${h.select('lifetime', '', c.lifetime_options)}
                            ${h.select('role', '', c.role_options)}
                        </div>
                     </div>
                    <div class="buttons">
                      ${h.submit('save',_('Add'),class_="btn btn-small")}
                      ${h.reset('reset',_('Reset'),class_="btn btn-small")}
                    </div>
                </div>
            </div>
            ${h.end_form()}
        </div>
    </div>
</div>

<script>
    $(document).ready(function(){
        $("#lifetime").select2({
            'containerCssClass': "drop-menu",
            'dropdownCssClass': "drop-menu-dropdown",
            'dropdownAutoWidth': true
        });
        $("#role").select2({
            'containerCssClass': "drop-menu",
            'dropdownCssClass': "drop-menu-dropdown",
            'dropdownAutoWidth': true
        });
    })
</script>
