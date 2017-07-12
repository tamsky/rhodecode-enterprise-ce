<%namespace name="its" file="/base/issue_tracker_settings.mako"/>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Issue Tracker / Wiki Patterns')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(h.url('admin_settings_issuetracker_save'), method='post')}
            ${its.issue_tracker_settings_table(
                patterns=c.issuetracker_entries.items(),
                form_url=h.url('admin_settings_issuetracker'),
                delete_url=h.url('admin_issuetracker_delete')
            )}
              <div class="buttons">
                  <button type="submit" class="btn btn-primary" id="save">${_('Save')}</button>
                  <button type="reset" class="btn">${_('Reset')}</button>
              </div>
         ${h.end_form()}
    </div>
</div>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Test Patterns')}</h3>
    </div>
    <div class="panel-body">
        ${its.issue_tracker_new_row()}
        ${its.issue_tracker_settings_test(test_url=h.url('admin_issuetracker_test'))}
    </div>
</div>




