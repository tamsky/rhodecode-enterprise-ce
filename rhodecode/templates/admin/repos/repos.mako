## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('Repositories administration')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    <input class="q_filter_box" id="q_filter" size="15" type="text" name="filter" placeholder="${_('quick filter...')}" value=""/>
    ${h.link_to(_('Admin'),h.route_path('admin_home'))} &raquo; <span id="repo_count">0</span> ${_('repositories')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='admin')}
</%def>

<%def name="main()">
<div class="box">
    <div class="title">
        ${self.breadcrumbs()}
        <ul class="links">
            %if h.HasPermissionAny('hg.admin','hg.create.repository')():
             <li>
               <a href="${h.route_path('repo_new')}" class="btn btn-small btn-success">${_(u'Add Repository')}</a>
             </li>
            %endif
        </ul>
    </div>
    <div id="repos_list_wrap">
        <table id="repo_list_table" class="display"></table>
    </div>
</div>

<script>
$(document).ready(function() {

    var get_datatable_count = function(){
      var api = $('#repo_list_table').dataTable().api();
      $('#repo_count').text(api.page.info().recordsDisplay);
    };


    // repo list
    $('#repo_list_table').DataTable({
      data: ${c.data|n},
      dom: 'rtp',
      pageLength: ${c.visual.admin_grid_items},
      order: [[ 0, "asc" ]],
      columns: [
         { data: {"_": "name",
                  "sort": "name_raw"}, title: "${_('Name')}", className: "td-componentname" },
         { data: 'menu', "bSortable": false, className: "quick_repo_menu" },
         { data: {"_": "desc",
                  "sort": "desc"}, title: "${_('Description')}", className: "td-description" },
         { data: {"_": "last_change",
                  "sort": "last_change_raw",
                  "type": Number}, title: "${_('Last Change')}", className: "td-time" },
         { data: {"_": "last_changeset",
                  "sort": "last_changeset_raw",
                  "type": Number}, title: "${_('Commit')}", className: "td-commit" },
         { data: {"_": "owner",
                  "sort": "owner"}, title: "${_('Owner')}", className: "td-user" },
         { data: {"_": "state",
                  "sort": "state"}, title: "${_('State')}", className: "td-tags td-state" },
         { data: {"_": "action",
                  "sort": "action"}, title: "${_('Action')}", className: "td-action", orderable: false }
      ],
      language: {
          paginate: DEFAULT_GRID_PAGINATION,
          emptyTable:_gettext("No repositories available yet.")
      },
      "initComplete": function( settings, json ) {
          get_datatable_count();
          quick_repo_menu();
      }
    });

    // update the counter when doing search
    $('#repo_list_table').on( 'search.dt', function (e,settings) {
      get_datatable_count();
    });

    // filter, filter both grids
    $('#q_filter').on( 'keyup', function () {
      var repo_api = $('#repo_list_table').dataTable().api();
      repo_api
        .columns(0)
        .search(this.value)
        .draw();
    });

    // refilter table if page load via back button
    $("#q_filter").trigger('keyup');
  });

</script>

</%def>
