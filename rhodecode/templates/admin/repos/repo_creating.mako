## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('{} Creating repository').format(c.repo_name)}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${_('Creating repository')} ${c.repo_name}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>
<%def name="main()">
<div class="box">
    <!-- box / title -->
    <div class="title">
        ${self.breadcrumbs()}
    </div>

    <div id="progress-message">
        ${_('Repository "%(repo_name)s" is being created, you will be redirected when this process is finished.' % {'repo_name':c.repo_name})}
    </div>

    <div id="progress">
        <div class="progress progress-striped active">
          <div class="progress-bar progress-bar" role="progressbar"
               aria-valuenow="100" aria-valuemin="0" aria-valuemax="100">
          </div>
        </div>
    </div>
</div>

<script>
(function worker() {
  var skipCheck = false;
  var url = "${h.route_path('repo_creating_check', repo_name=c.repo_name, _query=dict(task_id=c.task_id))}";
  $.ajax({
    url: url,
    timeout: 60*1000, // sets timeout to 60 seconds
    complete: function(resp) {
        if (resp.status === 200) {
            var jsonResponse = resp.responseJSON;

            if (jsonResponse === undefined) {
                setTimeout(function () {
                    // we might have a backend problem, try dashboard again
                    window.location = "${h.route_path('repo_summary', repo_name = c.repo_name)}";
                }, 3000);
            } else {
                if (skipCheck || jsonResponse.result === true) {
                    // success, means go to dashboard
                    window.location = "${h.route_path('repo_summary', repo_name = c.repo_name)}";
                } else {
                    // Schedule the next request when the current one's complete
                    setTimeout(worker, 1000);
                }
            }
        }
        else {
            var message = _gettext('Fetching repository state failed. Error code: {0} {1}. Try <a href="{2}">refreshing</a> this page.').format(resp.status, resp.statusText, url);
            var payload = {
                message: {
                    message: message,
                    level: 'error',
                    force: true
                }
            };
            $.Topic('/notifications').publish(payload);
        }
    }
  });
})();
</script>
</%def>
