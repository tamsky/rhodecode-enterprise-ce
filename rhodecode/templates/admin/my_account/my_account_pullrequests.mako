<%namespace name="base" file="/base/base.mako"/>

<div class="panel panel-default">
  <div class="panel-body">
      %if c.show_closed:
        ${h.checkbox('show_closed',checked="checked", label=_('Show Closed Pull Requests'))}
      %else:
        ${h.checkbox('show_closed',label=_('Show Closed Pull Requests'))}
      %endif
  </div>
</div>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Pull Requests You Participate In')}: ${c.records_total_participate}</h3>
    </div>
    <div class="panel-body">
        <table id="pull_request_list_table_participate" class="display"></table>
    </div>
</div>

<script>
    $('#show_closed').on('click', function(e){
        if($(this).is(":checked")){
            window.location = "${h.url('my_account_pullrequests', pr_show_closed=1)}";
        }
        else{
            window.location = "${h.url('my_account_pullrequests')}";
        }
    });
    $(document).ready(function() {

        var columnsDefs = [
             { data: {"_": "status",
                      "sort": "status"}, title: "", className: "td-status", orderable: false},
             { data: {"_": "target_repo",
                      "sort": "target_repo"}, title: "${_('Target Repo')}", className: "td-targetrepo", orderable: false},
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
        ];

        // participating object list
        $('#pull_request_list_table_participate').DataTable({
          data: ${c.data_participate|n},
          processing: true,
          serverSide: true,
          deferLoading: ${c.records_total_participate},
          ajax: "",
          dom: 'tp',
          pageLength: ${c.visual.dashboard_items},
          order: [[ 2, "desc" ]],
          columns: columnsDefs,
          language: {
                paginate: DEFAULT_GRID_PAGINATION,
                emptyTable: _gettext("There are currently no open pull requests requiring your participation.")
          },
          "drawCallback": function( settings, json ) {
              timeagoActivate();
          },
          "createdRow": function ( row, data, index ) {
              if (data['closed']) {
                $(row).addClass('closed');
              }
              if (data['owned']) {
                $(row).addClass('owned');
              }
          }
        });
    });
</script>