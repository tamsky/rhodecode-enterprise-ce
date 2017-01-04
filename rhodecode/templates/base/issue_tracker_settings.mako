## snippet for displaying issue tracker settings
## usage:
##    <%namespace name="its" file="/base/issue_tracker_settings.mako"/>
##    ${its.issue_tracker_settings_table(patterns, form_url, delete_url)}
##    ${its.issue_tracker_settings_test(test_url)}

<%def name="issue_tracker_settings_table(patterns, form_url, delete_url)">
    <table class="rctable issuetracker">
      <tr>
          <th>${_('Description')}</th>
          <th>${_('Pattern')}</th>
          <th>${_('Url')}</th>
          <th>${_('Prefix')}</th>
          <th ></th>
      </tr>
      <tr>
          <td class="td-description issue-tracker-example">Example</td>
          <td class="td-regex issue-tracker-example">${'(?:#)(?P<issue_id>\d+)'}</td>
          <td class="td-url issue-tracker-example">${'https://myissueserver.com/${repo}/issue/${issue_id}'}</td>
          <td class="td-prefix issue-tracker-example">#</td>
          ## TODO(skreft): add a link to the correct location of the Issue Tracker documentation.
          <td class="issue-tracker-example"><a href="https://rhodecode.com/docs" target="_blank">${_('Read more')}</a></td>
      </tr>
      %for uid, entry in patterns:
        <tr id="entry_${uid}">
                <td class="td-description issuetracker_desc">
                    <span class="entry">
                        ${entry.desc}
                    </span>
                    <span class="edit">
                        ${h.text('new_pattern_description_'+uid, class_='medium-inline', value=entry.desc or '')}
                    </span>
                </td>
                <td class="td-regex issuetracker_pat">
                    <span class="entry">
                        ${entry.pat}
                    </span>
                    <span class="edit">
                        ${h.text('new_pattern_pattern_'+uid, class_='medium-inline', value=entry.pat or '')}
                    </span>
                </td>
                <td class="td-url issuetracker_url">
                    <span class="entry">
                        ${entry.url}
                    </span>
                    <span class="edit">
                        ${h.text('new_pattern_url_'+uid, class_='medium-inline', value=entry.url or '')}
                    </span>
                </td>
                <td class="td-prefix issuetracker_pref">
                    <span class="entry">
                        ${entry.pref}
                    </span>
                    <span class="edit">
                        ${h.text('new_pattern_prefix_'+uid, class_='medium-inline', value=entry.pref or '')}
                    </span>
                </td>
                <td class="td-action">
                    <div  class="grid_edit">
                        <span class="entry">
                            <a class="edit_issuetracker_entry" href="">${_('Edit')}</a>
                        </span>
                        <span class="edit">
                            ${h.hidden('uid', uid)}
                        </span>
                    </div>
                    <div  class="grid_delete">
                        <span class="entry">
                            <a class="btn btn-link btn-danger delete_issuetracker_entry" data-desc="${entry.desc}" data-uid="${uid}">
                                ${_('Delete')}
                            </a>
                        </span>
                        <span class="edit">
                            <a class="btn btn-link btn-danger edit_issuetracker_cancel" data-uid="${uid}">${_('Cancel')}</a>
                        </span>
                   </div>
                </td>
        </tr>
      %endfor
      <tr id="last-row"></tr>
    </table>
    <p>
      <a id="add_pattern" class="link">
          ${_('Add new')}
      </a>
    </p>

    <script type="text/javascript">
        var newEntryLabel = $('label[for="new_entry"]');

        var resetEntry = function() {
          newEntryLabel.text("${_('New Entry')}:");
        };

        var delete_pattern = function(entry) {
          if (confirm("${_('Confirm to remove this pattern:')} "+$(entry).data('desc'))) {
            var request = $.ajax({
              type: "POST",
              url: "${delete_url}", 
              data: {
                '_method': 'delete',
                'csrf_token': CSRF_TOKEN,
                'uid':$(entry).data('uid')
              },
              success: function(){
                location.reload();
              },
              error: function(data, textStatus, errorThrown){
                  alert("Error while deleting entry.\nError code {0} ({1}). URL: {2}".format(data.status,data.statusText,$(entry)[0].url));
              }
            });
          }; 
        }

        $('.delete_issuetracker_entry').on('click', function(e){
          e.preventDefault();
          delete_pattern(this);
        });

        $('.edit_issuetracker_entry').on('click', function(e){
            e.preventDefault();
            $(this).parents('tr').addClass('editopen');
        });

        $('.edit_issuetracker_cancel').on('click', function(e){
            e.preventDefault();
            $(this).parents('tr').removeClass('editopen');
            // Reset to original value
            var uid = $(this).data('uid');
            $('#'+uid+' input').each(function(e) {
                this.value = this.defaultValue;
            });
        });

        $('input#reset').on('click', function(e) {
            resetEntry();
        });

        $('#add_pattern').on('click', function(e) {
            addNewPatternInput();
        });
    </script>    
</%def>

<%def name="issue_tracker_new_row()">
  <table id="add-row-tmpl" style="display: none;">
    <tbody>
    <tr class="new_pattern">
        <td class="td-description issuetracker_desc">
          <span class="entry">
                    <input class="medium-inline" id="description_##UUID##" name="new_pattern_description_##UUID##" value="##DESCRIPTION##" type="text">
          </span>
        </td>
        <td class="td-regex issuetracker_pat">
          <span class="entry">
                    <input class="medium-inline" id="pattern_##UUID##" name="new_pattern_pattern_##UUID##" placeholder="Pattern" 
                    value="##PATTERN##" type="text">
          </span>
        </td>
        <td class="td-url issuetracker_url">
          <span class="entry">
                  <input class="medium-inline" id="url_##UUID##" name="new_pattern_url_##UUID##" placeholder="Url" value="##URL##" type="text">
          </span>
        </td>
        <td class="td-prefix issuetracker_pref">
            <span class="entry">
                  <input class="medium-inline" id="prefix_##UUID##" name="new_pattern_prefix_##UUID##" placeholder="Prefix" value="##PREFIX##" type="text"> 
            </span>
        </td>
        <td class="td-action">
        </td>
        <input id="uid_##UUID##" name="uid_##UUID##" type="hidden" value="">
    </tr>
    </tbody>
  </table>
</%def>

<%def name="issue_tracker_settings_test(test_url)">
    <div class="form-vertical">
        <div class="fields">
            <div class="field">
                <div class='textarea-full'>
                    <textarea id="test_pattern_data" >
This commit fixes ticket #451.
This is an example text for testing issue tracker patterns, add a pattern here and
hit preview to see the link
                    </textarea>
                </div>
            </div>
        </div>
        <div class="test_pattern_preview">
            <div id="test_pattern" class="btn btn-small" >${_('Preview')}</div>
            <p>${_('Test Pattern Preview')}</p>
            <div id="test_pattern_result"></div>
        </div>
    </div>

    <script type="text/javascript">
        $('#test_pattern').on('click', function(e) {
          $.ajax({
              type: "POST",
              url: "${test_url}",
              data: {
                'test_text': $('#test_pattern_data').val(),
                'csrf_token': CSRF_TOKEN
              },
              success: function(data){
                  $('#test_pattern_result').html(data);
              },
              error: function(jqXHR, textStatus, errorThrown){
                  $('#test_pattern_result').html('Error: ' + errorThrown);
              }
          });
          $('#test_pattern_result').show();
        });
    </script>
</%def>


