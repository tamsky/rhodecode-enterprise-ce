<%namespace name="base" file="/base/base.mako"/>

<%
 elems = [
    (_('Owner'), lambda:base.gravatar_with_user(c.repo_info.user.email), '', ''),
    (_('Created on'), h.format_date(c.repo_info.created_on), '', ''),
    (_('Updated on'), h.format_date(c.repo_info.updated_on), '', ''),
    (_('Cached Commit id'), lambda: h.link_to(c.repo_info.changeset_cache.get('short_id'), h.url('changeset_home',repo_name=c.repo_name,revision=c.repo_info.changeset_cache.get('raw_id'))), '', ''),
 ]
%>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Repository: %s') % c.repo_info.repo_name}</h3>
    </div>
    <div class="panel-body">
        ${base.dt_info_panel(elems)}
    </div>
</div>


<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Fork Reference')}</h3>
    </div>
    <div class="panel-body">
      ${h.secure_form(url('edit_repo_advanced_fork', repo_name=c.repo_info.repo_name), method='put')}

        % if c.repo_info.fork:
            <div class="panel-body-title-text">${h.literal(_('This repository is a fork of %(repo_link)s') % {'repo_link': h.link_to_if(c.has_origin_repo_read_perm,c.repo_info.fork.repo_name, h.url('summary_home', repo_name=c.repo_info.fork.repo_name))})}
            | <button class="btn btn-link btn-danger" type="submit">Remove fork reference</button></div>
        % endif

         <div class="field">
             ${h.hidden('id_fork_of')}
             ${h.submit('set_as_fork_%s' % c.repo_info.repo_name,_('Set'),class_="btn btn-small",)}
         </div>
         <div class="field">
             <span class="help-block">${_('Manually set this repository as a fork of another from the list')}</span>
         </div>
      ${h.end_form()}
    </div>
</div>


<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Public Journal Visibility')}</h3>
    </div>
    <div class="panel-body">
      ${h.secure_form(url('edit_repo_advanced_journal', repo_name=c.repo_info.repo_name), method='put')}
        <div class="field">
        %if c.in_public_journal:
          <button class="btn btn-small" type="submit">
              <i class="icon-minus"></i>
              ${_('Remove from Public Journal')}
          </button>
        %else:
          <button class="btn btn-small" type="submit">
              ${_('Add to Public Journal')}
          </button>
        %endif
        </div>
       <div class="field" >
       <span class="help-block">${_('All actions made on this repository will be visible to everyone following the public journal.')}</span>
       </div>
      ${h.end_form()}
    </div>
</div>


<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Locking state')}</h3>
    </div>
    <div class="panel-body">
        ${h.secure_form(url('edit_repo_advanced_locking', repo_name=c.repo_info.repo_name), method='put')}

        %if c.repo_info.locked[0]:
             <div class="panel-body-title-text">${'Locked by %s on %s. Lock reason: %s' % (h.person_by_id(c.repo_info.locked[0]),
             h.format_date(h. time_to_datetime(c.repo_info.locked[1])), c.repo_info.locked[2])}</div>
        %else:
            <div class="panel-body-title-text">${_('This Repository is not currently locked.')}</div>
        %endif

        <div class="field" >
            %if c.repo_info.locked[0]:
              ${h.hidden('set_unlock', '1')}
              <button class="btn btn-small" type="submit"
                      onclick="return confirm('${_('Confirm to unlock repository.')}');">
                  <i class="icon-unlock"></i>
                  ${_('Unlock repository')}
              </button>
            %else:
              ${h.hidden('set_lock', '1')}
              <button class="btn btn-small" type="submit"
                      onclick="return confirm('${_('Confirm to lock repository.')}');">
                  <i class="icon-lock"></i>
                  ${_('Lock Repository')}
              </button>
            %endif
         </div>
         <div class="field" >
            <span class="help-block">
                ${_('Force repository locking. This only works when anonymous access is disabled. Pulling from the repository locks the repository to that user until the same user pushes to that repository again.')}
            </span>
         </div>
        ${h.end_form()}
    </div>
</div>

<div class="panel panel-danger">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Delete repository')}</h3>
    </div>
    <div class="panel-body">
      ${h.secure_form(url('repo', repo_name=c.repo_name),method='delete')}
        <table class="display">
            <tr>
                <td>
                    ${ungettext('This repository has %s fork.', 'This repository has %s forks.', c.repo_info.  forks.count()) % c.repo_info.forks.count()}
                </td>
                <td>
                    %if c.repo_info.forks.count():
                        <input type="radio" name="forks" value="detach_forks" checked="checked"/> <label for="forks">${_('Detach forks')}</label>
                    %endif
                </td>
                <td>
                    %if c.repo_info.forks.count():
                        <input type="radio" name="forks" value="delete_forks"/> <label for="forks">${_('Delete forks')}</label>
                    %endif
                </td>
            </tr>
        </table>
        <div style="margin: 0 0 20px 0" class="fake-space"></div>

        <div class="field">
            <button class="btn btn-small btn-danger" type="submit"
                    onclick="return confirm('${_('Confirm to delete this repository: %s') % c.repo_name}');">
                <i class="icon-remove-sign"></i>
                ${_('Delete This Repository')}
            </button>
        </div>
        <div class="field">
            <span class="help-block">
                ${_('This repository will be renamed in a special way in order to make it inaccessible to RhodeCode Enterprise and its VCS systems. If you need to fully delete it from the file system, please do it manually, or with rhodecode-cleanup-repos command.')}
            </span>
        </div>

      ${h.end_form()}
    </div>
</div>


<script>

var currentRepoId = ${c.repo_info.repo_id};

var repoTypeFilter = function(data) {
    var results = [];

    if (!data.results[0]) {
        return data
    }

    $.each(data.results[0].children, function() {
        // filter out the SAME repo, it cannot be used as fork of itself
        if (this.obj.repo_id != currentRepoId) {
            this.id = this.obj.repo_id;
            results.push(this)
        }
    });
    data.results[0].children = results;
    return data;
};

$("#id_fork_of").select2({
    cachedDataSource: {},
    minimumInputLength: 2,
    placeholder: "${_('Change repository') if c.repo_info.fork else _('Pick repository')}",
    dropdownAutoWidth: true,
    containerCssClass: "drop-menu",
    dropdownCssClass: "drop-menu-dropdown",
    formatResult: formatResult,
    query: $.debounce(250, function(query){
        self = this;
        var cacheKey = query.term;
        var cachedData = self.cachedDataSource[cacheKey];

        if (cachedData) {
            query.callback({results: cachedData.results});
        } else {
            $.ajax({
                url: "${h.url('repo_list_data')}",
                data: {'query': query.term, repo_type: '${c.repo_info.repo_type}'},
                dataType: 'json',
                type: 'GET',
                success: function(data) {
                    data = repoTypeFilter(data);
                    self.cachedDataSource[cacheKey] = data;
                    query.callback({results: data.results});
                },
                error: function(data, textStatus, errorThrown) {
                    alert("Error while fetching entries.\nError code {0} ({1}).".format(data.status, data.statusText));
                }
            })
        }
    })
});
</script>

