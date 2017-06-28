<%inherit file="/summary/base.mako"/>

<%namespace name="components" file="/summary/components.mako"/>


<%def name="menu_bar_subnav()">
    ${self.repo_menu(active='summary')}
</%def>

<%def name="main()">

<div class="title">
    ${self.repo_page_title(c.rhodecode_db_repo)}
    <ul class="links icon-only-links block-right">
      <li>
     %if c.rhodecode_user.username != h.DEFAULT_USER:
       <a href="${h.url('atom_feed_home',repo_name=c.rhodecode_db_repo.repo_name,auth_token=c.rhodecode_user.feed_token)}" title="${_('RSS Feed')}"><i class="icon-rss-sign"></i></a>
     %else:
       <a href="${h.url('atom_feed_home',repo_name=c.rhodecode_db_repo.repo_name)}" title="${_('RSS Feed')}"><i class="icon-rss-sign"></i></a>
     %endif
      </li>
    </ul>
</div>

<div id="repo-summary" class="summary">
    ${components.summary_detail(breadcrumbs_links=self.breadcrumbs_links(), show_downloads=True)}
    ${components.summary_stats(gravatar_function=self.gravatar_with_user)}
</div><!--end repo-summary-->


<div class="box" >
    %if not c.repo_commits:
        <div class="title">
          <h3>${_('Quick start')}</h3>
        </div>
     %endif
    <div class="table">
        <div id="shortlog_data">
            <%include file='summary_commits.mako'/>
        </div>
    </div>
</div>

%if c.readme_data:
<div id="readme" class="anchor">
<div class="box" >
    <div class="title" title="${h.tooltip(_('Readme file from commit %s:%s') % (c.rhodecode_db_repo.landing_rev[0], c.rhodecode_db_repo.landing_rev[1]))}">
        <h3 class="breadcrumbs">
            <a href="${h.url('files_home',repo_name=c.repo_name,revision='tip',f_path=c.readme_file)}">${c.readme_file}</a>
        </h3>
    </div>
    <div class="readme codeblock">
      <div class="readme_box">
        ${c.readme_data|n}
      </div>
    </div>
</div>
</div>
%endif

<script type="text/javascript">
$(document).ready(function(){
    $('#clone_by_name').on('click',function(e){
        // show url by name and hide name button
        $('#clone_url').show();
        $('#clone_by_name').hide();

        // hide url by id and show name button
        $('#clone_by_id').show();
        $('#clone_url_id').hide();

    });
    $('#clone_by_id').on('click',function(e){

        // show url by id and hide id button
        $('#clone_by_id').hide();
        $('#clone_url_id').show();

        // hide url by name and show id button
        $('#clone_by_name').show();
        $('#clone_url').hide();
    });

    var initialCommitData = {
        id: null,
        text: 'tip',
        type: 'tag',
        raw_id: null,
        files_url: null
    };

    select2RefSwitcher('#download_options', initialCommitData);

    // on change of download options
    $('#download_options').on('change', function(e) {
        // format of Object {text: "v0.0.3", type: "tag", id: "rev"}
        var selected_cs = e.added;
        var fname= e.added.raw_id + ".zip";
        var href = pyroutes.url('files_archive_home', {'repo_name': templateContext.repo_name, 'fname':fname});
        // set new label
        $('#archive_link').html('<i class="icon-archive"></i> '+ e.added.text+".zip");

        // set new url to button,
        $('#archive_link').attr('href', href)
    });


    // load details on summary page expand
    $('#summary_details_expand').on('click', function() {

        var callback = function (data) {
            % if c.show_stats:
                showRepoStats('lang_stats', data);
            % endif
        };

        showRepoSize(
            'repo_size_container',
            templateContext.repo_name,
            templateContext.repo_landing_commit,
            callback);

    })

})
</script>

</%def>
