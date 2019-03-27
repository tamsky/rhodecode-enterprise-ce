## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('Repository groups administration')}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    <input class="q_filter_box" id="q_filter" size="15" type="text" name="filter" placeholder="${_('quick filter...')}" value=""/>
    ${h.link_to(_('Admin'),h.route_path('admin_home'))} &raquo; <span id="repo_group_count">0</span> ${_('repository groups')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='admin')}
</%def>

<%def name="menu_bar_subnav()">
    ${self.admin_menu(active='repository_groups')}
</%def>

<%def name="main()">
<div class="box">
    <div class="title">

        <ul class="links">
            %if c.can_create_repo_group:
             <li>
               <a href="${h.route_path('repo_group_new')}" class="btn btn-small btn-success">${_(u'Add Repository Group')}</a>
             </li>
            %endif
        </ul>
    </div>
    <div id="repos_list_wrap">
        <table id="group_list_table" class="display"></table>
    </div>
</div>

<script>
$(document).ready(function() {

    var get_datatable_count = function(){
      var api = $('#group_list_table').dataTable().api();
      $('#repo_group_count').text(api.page.info().recordsDisplay);
    };

   // repo group list
   $('#group_list_table').DataTable({
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
         { data: {"_": "top_level_repos",
                  "sort": "top_level_repos"}, title: "${_('Number of top level repositories')}" },
         { data: {"_": "owner",
                  "sort": "owner"}, title: "${_('Owner')}", className: "td-user" },
         { data: {"_": "action",
                  "sort": "action"}, title: "${_('Action')}", className: "td-action" }
      ],
      language: {
          paginate: DEFAULT_GRID_PAGINATION,
          emptyTable: _gettext("No repository groups available yet.")
      },
      "initComplete": function( settings, json ) {
          get_datatable_count();
          quick_repo_menu();
      }
    });

     // update the counter when doing search
    $('#group_list_table').on( 'search.dt', function (e,settings) {
      get_datatable_count();
    });

    // filter, filter both grids
    $('#q_filter').on( 'keyup', function () {

      var repo_group_api = $('#group_list_table').dataTable().api();
      repo_group_api
        .columns(0)
        .search(this.value)
        .draw();
    });

    // refilter table if page load via back button
    $("#q_filter").trigger('keyup');
});
</script>
</%def>

