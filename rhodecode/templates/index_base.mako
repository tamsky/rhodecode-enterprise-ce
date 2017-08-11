<%inherit file="/base/base.mako"/>

<%def name="main()">
   <div class="box">
        <!-- box / title -->
        <div class="title">
            <div class="block-left breadcrumbs">
              <input class="q_filter_box" id="q_filter" size="15" type="text" name="filter" placeholder="${_('quick filter...')}" value=""/>
              ${self.breadcrumbs()}
              <span id="match_container" style="display:none">&raquo; <span id="match_count">0</span> ${_('matches')}</span>
            </div>
            %if c.rhodecode_user.username != h.DEFAULT_USER:
              <div class="block-right">
                <%
                    is_admin = h.HasPermissionAny('hg.admin')('can create repos index page')
                    create_repo = h.HasPermissionAny('hg.create.repository')('can create repository index page')
                    create_repo_group = h.HasPermissionAny('hg.repogroup.create.true')('can create repository groups index page')
                    create_user_group = h.HasPermissionAny('hg.usergroup.create.true')('can create user groups index page')

                    gr_name = c.repo_group.group_name if c.repo_group else None
                    # create repositories with write permission on group is set to true
                    create_on_write = h.HasPermissionAny('hg.create.write_on_repogroup.true')()
                    group_admin = h.HasRepoGroupPermissionAny('group.admin')(gr_name, 'group admin index page')
                    group_write = h.HasRepoGroupPermissionAny('group.write')(gr_name, 'can write into group index page')
                %>

                %if not c.repo_group:
                    ## no repository group context here
                    %if is_admin or create_repo:
                        <a href="${h.route_path('repo_new')}" class="btn btn-small btn-success btn-primary">${_('Add Repository')}</a>
                    %endif

                    %if is_admin or create_repo_group:
                        <a href="${h.url('new_repo_group')}" class="btn btn-small btn-default">${_(u'Add Repository Group')}</a>
                    %endif
                %else:
                    ##we're inside other repository group other terms apply
                    %if is_admin or group_admin or (group_write and create_on_write):
                        <a href="${h.route_path('repo_new',parent_group=c.repo_group.group_id)}" class="btn btn-small btn-success btn-primary">${_('Add Repository')}</a>
                    %endif
                    %if is_admin or group_admin:
                        <a href="${h.url('new_repo_group', parent_group=c.repo_group.group_id)}" class="btn btn-small btn-default">${_(u'Add Repository Group')}</a>
                    %endif
                    %if is_admin or group_admin:
                        <a href="${h.url('edit_repo_group',group_name=c.repo_group.group_name)}" title="${_('You have admin right to this group, and can edit it')}" class="btn btn-small btn-primary">${_('Edit Repository Group')}</a>
                    %endif
                %endif
              </div>
            %endif
        </div>
        <!-- end box / title -->
        <div class="table">
            <div id="groups_list_wrap">
                <table id="group_list_table" class="display"></table>
            </div>
        </div>

        <div class="table">
            <div id="repos_list_wrap">
                <table id="repo_list_table" class="display"></table>
            </div>
        </div>
    </div>
    <script>
      $(document).ready(function() {

        var get_datatable_count = function() {
          var api = $('#repo_list_table').dataTable().api();
          var pageInfo = api.page.info();
          var repos = pageInfo.recordsDisplay;
          var reposTotal = pageInfo.recordsTotal;

          api = $('#group_list_table').dataTable().api();
          pageInfo = api.page.info();
          var repoGroups = pageInfo.recordsDisplay;
          var repoGroupsTotal = pageInfo.recordsTotal;

          if (repoGroups !== repoGroupsTotal) {
            $('#match_count').text(repos+repoGroups);
          }
          if (repos !== reposTotal) {
            $('#match_container').show();
          }
          if ($('#q_filter').val() === '') {
            $('#match_container').hide();
          }
        };

       // repo group list
       $('#group_list_table').DataTable({
          data: ${c.repo_groups_data|n},
          dom: 'rtp',
          pageLength: ${c.visual.dashboard_items},
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
             { data: {"_": "owner",
                      "sort": "owner"}, title: "${_('Owner')}", className: "td-user" }
          ],
          language: {
            paginate: DEFAULT_GRID_PAGINATION,
            emptyTable: _gettext("No repository groups available yet.")
          },
          "drawCallback": function( settings, json ) {
              timeagoActivate();
              quick_repo_menu();
          }
        });

        // repo list
        $('#repo_list_table').DataTable({
          data: ${c.repos_data|n},
          dom: 'rtp',
          order: [[ 0, "asc" ]],
          pageLength: ${c.visual.dashboard_items},
          columns: [
             { data: {"_": "name",
                      "sort": "name_raw"}, title: "${_('Name')}", className: "truncate-wrap td-componentname" },
             { data: 'menu', "bSortable": false, className: "quick_repo_menu" },
             { data: {"_": "desc",
                      "sort": "desc"}, title: "${_('Description')}", className: "td-description" },
             { data: {"_": "last_change",
                      "sort": "last_change_raw",
                      "type": Number}, title: "${_('Last Change')}", className: "td-time" },
             { data: {"_": "last_changeset",
                      "sort": "last_changeset_raw",
                      "type": Number}, title: "${_('Commit')}", className: "td-hash" },
             { data: {"_": "owner",
                      "sort": "owner"}, title: "${_('Owner')}", className: "td-user" },
          ],
          language: {
              paginate: DEFAULT_GRID_PAGINATION,
              emptyTable: _gettext("No repositories available yet.")
          },
          "drawCallback": function( settings, json ) {
              timeagoActivate();
              quick_repo_menu();
          }
        });

        // update the counter when doing search
       $('#repo_list_table, #group_list_table').on( 'search.dt', function (e,settings) {
          get_datatable_count();
        });

        // filter, filter both grids
        $('#q_filter').on( 'keyup', function () {
          var repo_api = $('#repo_list_table').dataTable().api();
          repo_api
            .columns( 0 )
            .search( this.value )
            .draw();

          var repo_group_api = $('#group_list_table').dataTable().api();
          repo_group_api
            .columns( 0 )
            .search( this.value )
            .draw();
        });

        // refilter table if page load via back button
        $("#q_filter").trigger('keyup');

      });
    </script>
</%def>
