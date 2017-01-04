<%inherit file="/summary/base.mako"/>

<%namespace name="components" file="/summary/components.mako"/>

<%def name="main()">
    <div class="title">
      ${self.repo_page_title(c.rhodecode_db_repo)}
    </div>

  <div id="repo-summary" class="summary">
    ${components.summary_detail(breadcrumbs_links=self.breadcrumbs_links(), show_downloads=False)}
    ${components.summary_stats(gravatar_function=self.gravatar_with_user)}
  </div><!--end repo-summary-->

  <div class="alert alert-dismissable alert-warning">
    <strong>Missing requirements</strong>
    These commits cannot be displayed, because this repository uses the Mercurial largefiles extension, which was not enabled.
    Please <a href="${h.url('repo_vcs_settings', repo_name=c.repo_name)}">enable this extension in settings</a>, or contact the repository owner for help.
  </div>

</%def>


<%def name="menu_bar_subnav()">
    ${self.repo_menu(active='summary')}
</%def>
