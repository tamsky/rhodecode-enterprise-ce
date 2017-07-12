<%namespace name="vcss" file="/base/vcs_settings.mako"/>

<div id="repo_vcs_settings" class="${'inherited' if c.inherit_global_settings else ''}">
    ${h.secure_form(h.url('repo_vcs_settings', repo_name=c.repo_info.repo_name), method='post')}
        <div class="form panel panel-default">
            <div class="fields panel-body">
                <div class="field">
                    <div class="label label-checkbox">
                        <label for="inherit_global_settings">${_('Inherit from global settings')}:</label>
                    </div>
                    <div class="checkboxes">
                        ${h.checkbox('inherit_global_settings',value=True)}
                        <span class="help-block">${h.literal(_('Select to inherit global vcs settings.'))}</span>
                    </div>
                </div>
            </div>
        </div>

        <div id="inherit_overlay_vcs_default">
            <div>
                ${vcss.vcs_settings_fields(
                    suffix='_inherited',
                    svn_tag_patterns=c.global_svn_tag_patterns,
                    svn_branch_patterns=c.global_svn_branch_patterns,
                    repo_type=c.repo_info.repo_type,
                    disabled='disabled'
                )}
            </div>
        </div>

        <div id="inherit_overlay_vcs_custom">
            <div>
                ${vcss.vcs_settings_fields(
                    suffix='',
                    svn_tag_patterns=c.svn_tag_patterns,
                    svn_branch_patterns=c.svn_branch_patterns,
                    repo_type=c.repo_info.repo_type
                )}
            </div>
        </div>

        <div class="buttons">
                ${h.submit('save',_('Save settings'),class_="btn")}
                ${h.reset('reset',_('Reset'),class_="btn")}
        </div>

    ${h.end_form()}
</div>

<script type="text/javascript">

    function ajaxDeletePattern(pattern_id, field_id) {
        var sUrl = "${h.url('repo_vcs_settings', repo_name=c.repo_info.repo_name)}";
        var callback =  function (o) {
            var elem = $("#"+field_id);
            elem.remove();
        };
        var postData = {
            '_method': 'delete',
            'delete_svn_pattern': pattern_id,
            'csrf_token': CSRF_TOKEN
        };
        var request = $.post(sUrl, postData)
            .done(callback)
            .fail(function (data, textStatus, errorThrown) {
                alert("Error while deleting hooks.\nError code {0} ({1}). URL: {2}".format(data.status,data.statusText,$(this)[0].url));
            });
    }

    $('#inherit_global_settings').on('change', function(e){
        $('#repo_vcs_settings').toggleClass('inherited', this.checked);
    });

</script>
