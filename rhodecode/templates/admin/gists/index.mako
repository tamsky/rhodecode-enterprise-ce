## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    %if c.show_private:
        ${_('Private Gists for user %s') % c.rhodecode_user.username}
    %elif c.show_public:
        ${_('Public Gists for user %s') % c.rhodecode_user.username}
    %else:
        ${_('Public Gists')}
    %endif
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()"></%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='gists')}
</%def>



<%def name="main()">

<div class="box">
  <div class="title">

    <ul class="button-links">
      % if c.is_super_admin:
        <li class="btn ${'active' if c.active=='all' else ''}"><a href="${h.route_path('gists_show', _query={'all': 1})}">${_('All gists')}</a></li>
      %endif
      <li class="btn ${'active' if c.active=='public' else ''}"><a href="${h.route_path('gists_show')}">${_('All public')}</a></li>
      %if c.rhodecode_user.username != h.DEFAULT_USER:
        <li class="btn ${'active' if c.active=='my_all' else ''}"><a href="${h.route_path('gists_show', _query={'public':1, 'private': 1})}">${_('My gists')}</a></li>
        <li class="btn ${'active' if c.active=='my_private' else ''}"><a href="${h.route_path('gists_show', _query={'private': 1})}">${_('My private')}</a></li>
        <li class="btn ${'active' if c.active=='my_public' else ''}"><a href="${h.route_path('gists_show', _query={'public': 1})}">${_('My public')}</a></li>
      %endif
    </ul>

    % if c.rhodecode_user.username != h.DEFAULT_USER:
        <div class="pull-right">
            <a class="btn btn-primary" href="${h.route_path('gists_new')}" >
                ${_(u'Create New Gist')}
            </a>
        </div>
    % endif

    <div class="grid-quick-filter">
        <ul class="grid-filter-box">
            <li class="grid-filter-box-icon">
                <i class="icon-search"></i>
            </li>
            <li class="grid-filter-box-input">
                <input class="q_filter_box" id="q_filter" size="15" type="text" name="filter" placeholder="${_('quick filter...')}" value=""/>
            </li>
        </ul>
    </div>

  </div>

    <div class="main-content-full-width">
        <div id="repos_list_wrap">
            <table id="gist_list_table" class="display"></table>
        </div>
    </div>

</div>

<script type="text/javascript">
$(document).ready(function() {

    var get_datatable_count = function(){
      var api = $('#gist_list_table').dataTable().api();
      $('#gists_count').text(api.page.info().recordsDisplay);
    };


    // custom filter that filters by access_id, description or author
    $.fn.dataTable.ext.search.push(
        function( settings, data, dataIndex ) {
            var query = $('#q_filter').val();
            var author = data[0].strip();
            var access_id = data[2].strip();
            var description = data[3].strip();

            var query_str = (access_id + " " + author + " " + description).toLowerCase();

            if(query_str.indexOf(query.toLowerCase()) !== -1){
                return true;
            }
            return false;
        }
    );

    // gists list
    $('#gist_list_table').DataTable({
      data: ${c.data|n},
      dom: 'rtp',
      pageLength: ${c.visual.dashboard_items},
      order: [[ 4, "desc" ]],
      columns: [
         { data: {"_": "author",
                  "sort": "author_raw"}, title: "${_("Author")}", width: "250px", className: "td-user" },
         { data: {"_": "type",
                  "sort": "type"}, title: "${_("Type")}", width: "70px", className: "td-tags" },
         { data: {"_": "access_id",
                  "sort": "access_id"}, title: "${_("Name")}", width:"150px", className: "td-componentname" },
         { data: {"_": "description",
                  "sort": "description"}, title: "${_("Description")}", width: "250px", className: "td-description" },
         { data: {"_": "created_on",
                  "sort": "created_on_raw"}, title: "${_("Created on")}", className: "td-time" },
         { data: {"_": "expires",
                  "sort": "expires"}, title: "${_("Expires")}", className: "td-exp" }
      ],
      language: {
          paginate: DEFAULT_GRID_PAGINATION,
          emptyTable: _gettext("No gists available yet.")
      },
      "initComplete": function( settings, json ) {
          timeagoActivate();
          get_datatable_count();
      }
    });

    // update the counter when things change
    $('#gist_list_table').on('draw.dt', function() {
        timeagoActivate();
        get_datatable_count();
    });

    // filter, filter both grids
    $('#q_filter').on( 'keyup', function () {
      var repo_api = $('#gist_list_table').dataTable().api();
      repo_api
        .draw();
    });

    // refilter table if page load via back button
    $("#q_filter").trigger('keyup');

  });

</script>
</%def>

