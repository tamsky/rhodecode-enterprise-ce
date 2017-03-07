<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('%s Pull Requests') % c.repo_name}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">

</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>


<%def name="menu_bar_subnav()">
    ${self.repo_menu(active='showpullrequest')}
</%def>


<%def name="main()">
<div class="box">
  <div class="title">
      ${self.repo_page_title(c.rhodecode_db_repo)}

      <ul class="links">
        <li>
           %if c.rhodecode_user.username != h.DEFAULT_USER:
            <span>
                <a id="open_new_pull_request" class="btn btn-small btn-success" href="${h.url('pullrequest_home',repo_name=c.repo_name)}">
                    ${_('Open new Pull Request')}
                </a>
            </span>
           %endif
        </li>
      </ul>

    ${self.breadcrumbs()}
  </div>

  <div class="sidebar-col-wrapper">
    ##main
    <div class="sidebar">
        <ul class="nav nav-pills nav-stacked">
          <li class="${'active' if c.active=='open' else ''}"><a href="${h.url('pullrequest_show_all',repo_name=c.repo_name,source=0)}">${_('Opened')}</a></li>
          <li class="${'active' if c.active=='my' else ''}"><a href="${h.url('pullrequest_show_all',repo_name=c.repo_name,source=0,my=1)}">${_('Opened by me')}</a></li>
          <li class="${'active' if c.active=='awaiting' else ''}"><a href="${h.url('pullrequest_show_all',repo_name=c.repo_name,source=0,awaiting_review=1)}">${_('Awaiting review')}</a></li>
          <li class="${'active' if c.active=='awaiting_my' else ''}"><a href="${h.url('pullrequest_show_all',repo_name=c.repo_name,source=0,awaiting_my_review=1)}">${_('Awaiting my review')}</a></li>
          <li class="${'active' if c.active=='closed' else ''}"><a href="${h.url('pullrequest_show_all',repo_name=c.repo_name,source=0,closed=1)}">${_('Closed')}</a></li>
          <li class="${'active' if c.active=='source' else ''}"><a href="${h.url('pullrequest_show_all',repo_name=c.repo_name,source=1)}">${_('From this repo')}</a></li>
        </ul>
    </div>

    <div class="main-content-full-width">
      <div class="panel panel-default">
        <div class="panel-heading">
          <h3 class="panel-title">
              %if c.source:
                  ${_('Pull Requests from %(repo_name)s repository') % {'repo_name': c.repo_name}}
              %elif c.closed:
                  ${_('Closed Pull Requests to repository %(repo_name)s') % {'repo_name': c.repo_name}}
              %elif c.my:
                  ${_('Pull Requests to %(repo_name)s repository opened by me') % {'repo_name': c.repo_name}}
              %elif c.awaiting_review:
                  ${_('Pull Requests to %(repo_name)s repository awaiting review') % {'repo_name': c.repo_name}}
              %elif c.awaiting_my_review:
                  ${_('Pull Requests to %(repo_name)s repository awaiting my review') % {'repo_name': c.repo_name}}
              %else:
                  ${_('Pull Requests to %(repo_name)s repository') % {'repo_name': c.repo_name}}
              %endif
          </h3>
        </div>
        <div class="panel-body">
          <table id="pull_request_list_table" class="display"></table>
        </div>
      </div>
    </div>
  </div>
</div>

<script type="text/javascript">
$(document).ready(function() {
    // object list
    $('#pull_request_list_table').DataTable({
      data: ${c.data|n},
      processing: false,
      serverSide: true,
      deferLoading: ${c.records_total},
      ajax: "",
      dom: 'tp',
      pageLength: ${c.visual.dashboard_items},
      order: [[ 1, "desc" ]],
      columns: [
         { data: {"_": "status",
                  "sort": "status"}, title: "", className: "td-status", orderable: false},
         { data: {"_": "name",
                  "sort": "name_raw"}, title: "${_('Name')}", className: "td-componentname", "type": "num" },
         { data: {"_": "author",
                  "sort": "author_raw"}, title: "${_('Author')}", className: "td-user", orderable: false },
         { data: {"_": "title",
                  "sort": "title"}, title: "${_('Title')}", className: "td-description" },
         { data: {"_": "comments",
                  "sort": "comments_raw"}, title: "", className: "td-comments", orderable: false},
         { data: {"_": "updated_on",
                  "sort": "updated_on_raw"}, title: "${_('Last Update')}", className: "td-time" }
      ],
      language: {
            paginate: DEFAULT_GRID_PAGINATION,
            emptyTable: _gettext("No pull requests available yet.")
      },
      "drawCallback": function( settings, json ) {
          timeagoActivate();
      },
      "createdRow": function ( row, data, index ) {
          if (data['closed']) {
            $(row).addClass('closed');
          }
      }
    });
});
$('#pull_request_list_table').on('xhr.dt', function(e, settings, json, xhr){
    $('#pull_request_list_table').css('opacity', 1);
});

$('#pull_request_list_table').on('preXhr.dt', function(e, settings, data){
    $('#pull_request_list_table').css('opacity', 0.3);
});
</script>
</%def>
