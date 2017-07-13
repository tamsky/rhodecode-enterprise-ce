<%namespace name="base" file="/base/base.mako"/>

<div class="panel panel-default">
  <div class="panel-heading">
    <h3 class="panel-title">${_('Account Emails')}</h3>
  </div>

    <div class="panel-body">
        <div class="emails_wrap">
          <table class="rctable account_emails">
            <tr>
            <td class="td-user">
                ${base.gravatar(c.user.email, 16)}
                <span class="user email">${c.user.email}</span>
            </td>
            <td class="td-tags">
                <span class="tag tag1">${_('Primary')}</span>
            </td>
            </tr>
            %if c.user_email_map:
                %for em in c.user_email_map:
                  <tr>
                    <td class="td-user">
                        ${base.gravatar(em.email, 16)}
                        <span class="user email">${em.email}</span>
                    </td>
                    <td class="td-action">
                        ${h.secure_form(h.route_path('my_account_emails_delete'), method='POST', request=request)}
                            ${h.hidden('del_email_id',em.email_id)}
                            <button class="btn btn-link btn-danger" type="submit" id="${'remove_email_%s'.format(em.email_id)}"
                                    onclick="return confirm('${_('Confirm to delete this email: {}').format(em.email)}');">
                                ${_('Delete')}
                            </button>
                        ${h.end_form()}
                    </td>
                  </tr>
                %endfor
            %else:
                <tr class="noborder">
                    <td colspan="3">
                        <div class="td-email">
                            ${_('No additional emails specified')}
                        </div>
                    </td>
                </tr>
            %endif
          </table>
        </div>

        <div>
            ${h.secure_form(h.route_path('my_account_emails_add'), method='POST', request=request)}
            <div class="form">
                <!-- fields -->
                <div class="fields">
                     <div class="field">
                        <div class="label">
                            <label for="new_email">${_('New email address')}:</label>
                        </div>
                        <div class="input">
                            ${h.text('new_email', class_='medium')}
                        </div>
                     </div>
                    <div class="buttons">
                      ${h.submit('save',_('Add'),class_="btn")}
                      ${h.reset('reset',_('Reset'),class_="btn")}
                    </div>
                </div>
            </div>
            ${h.end_form()}
        </div>
    </div>
</div>
