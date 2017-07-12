<%namespace name="its" file="/base/issue_tracker_settings.mako"/>

<div id="repo_issue_tracker" class="${'inherited' if c.settings_model.inherit_global_settings else ''}">
  ${h.secure_form(h.url('repo_issuetracker_save', repo_name=c.repo_name), method='post', id="inherit-form")}
      <div class="panel panel-default panel-body">
          <div class="fields">
              <div class="field">
                  <div class="label label-checkbox">
                      <label for="inherit_default_permissions">${_('Inherit from global settings')}:</label>
                  </div>
                  <div class="checkboxes">
                      ${h.checkbox('inherit_global_issuetracker', value='inherited', checked=c.settings_model.inherit_global_settings)}
                      <span class="help-block">
                      ${h.literal(_('Select to inherit global patterns for issue tracker.'))}
                      </span>
                  </div>
              </div>
          </div>
      </div>

      <div id="inherit_overlay">
        <div class="panel panel-default">
            <div class="panel-heading">
                <h3 class="panel-title">${_('Inherited Issue Tracker Patterns')}</h3>
            </div>
            <div class="panel-body">
                <table class="rctable issuetracker readonly">
          <tr>
              <th>${_('Description')}</th>
              <th>${_('Pattern')}</th>
              <th>${_('Url')}</th>
              <th>${_('Prefix')}</th>
              <th ></th>
          </tr>
              %for uid, entry in c.global_patterns.items():
            <tr id="${uid}">
                <td class="td-description issuetracker_desc">
                  <span class="entry">
                    ${entry.desc}
                  </span>
                </td>
                <td class="td-regex issuetracker_pat">
                  <span class="entry">
                    ${entry.pat}
                  </span>
                </td>
                <td class="td-url issuetracker_url">
                  <span class="entry">
                    ${entry.url}
                  </span>
                </td>
                <td class="td-prefix issuetracker_pref">
                  <span class="entry">
                    ${entry.pref}
                  </span>
                </td>
                <td class="td-action">
                </td>
            </tr>
          %endfor

          </table>
            </div>
        </div>
      </div>

      <div id="custom_overlay">
        <div class="panel panel-default">
            <div class="panel-heading">
                <h3 class="panel-title">${_('Issue Tracker / Wiki Patterns')}</h3>
            </div>
            <div class="panel-body">
                    ${its.issue_tracker_settings_table(
                        patterns=c.repo_patterns.items(),
                        form_url=h.url('repo_settings_issuetracker', repo_name=c.repo_info.repo_name),
                        delete_url=h.url('repo_issuetracker_delete', repo_name=c.repo_info.repo_name)
                    )}
                  <div class="buttons">
                      <button type="submit" class="btn btn-primary save-inheritance" id="save">${_('Save')}</button>
                      <button type="reset" class="btn reset-inheritance">${_('Reset')}</button>
                  </div>
            </div>
        </div>
      </div>


  ${h.end_form()}

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Test Patterns')}</h3>
    </div>
    <div class="panel-body">
        ${its.issue_tracker_new_row()}
        ${its.issue_tracker_settings_test(test_url=h.url('repo_issuetracker_test', repo_name=c.repo_info.repo_name))}
    </div>
</div>

</div>

<script>
  $('#inherit_global_issuetracker').on('change', function(e){
    $('#repo_issue_tracker').toggleClass('inherited',this.checked);
  });

  $('.reset-inheritance').on('click', function(e){
     $('#inherit_global_issuetracker').prop('checked', false).change();
  });
</script>
