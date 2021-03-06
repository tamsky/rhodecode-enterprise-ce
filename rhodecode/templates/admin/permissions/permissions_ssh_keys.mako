
<div class="panel panel-default">
  <div class="panel-heading">
      <h3 class="panel-title">${_('SSH Keys')} - <span id="ssh_keys_count"></span></h3>

      ${h.secure_form(h.route_path('admin_permissions_ssh_keys_update'), request=request)}
        <button class="btn btn-link pull-right" type="submit">${_('Update SSH keys file')}</button>
      ${h.end_form()}
  </div>
  <div class="panel-body">
    <input class="q_filter_box" id="q_filter" size="15" type="text" name="filter" placeholder="${_('quick filter...')}" value=""/>

    <div id="repos_list_wrap">
        <table id="ssh_keys_table" class="display"></table>
    </div>
  </div>
</div>


<script type="text/javascript">

$(document).ready(function() {
    var $sshKeyListTable = $('#ssh_keys_table');

    // user list
    $sshKeyListTable.DataTable({
      processing: true,
      serverSide: true,
      ajax: {
          "url": "${h.route_path('admin_permissions_ssh_keys_data')}",
          "dataSrc": function ( json ) {
              var filteredCount = json.recordsFiltered;
              var total = json.recordsTotal;

              var _text = _gettext("{0} out of {1} ssh keys").format(filteredCount, total);
              $('#ssh_keys_count').text(_text);
              return json.data;
          }
      },
      dom: 'rtp',
      pageLength: ${c.visual.admin_grid_items},
      order: [[ 0, "asc" ]],
      columns: [
         { data: {"_": "username",
                  "sort": "username"}, title: "${_('Username')}", className: "td-user" },
         { data: {"_": "fingerprint",
                  "sort": "fingerprint"}, title: "${_('Fingerprint')}", className: "td-type"  },
         { data: {"_": "description",
                  "sort": "description"}, title: "${_('Description')}", className: "td-type"  },
         { data: {"_": "created_on",
                  "sort": "created_on"}, title: "${_('Created on')}", className: "td-time" },
         { data: {"_": "accessed_on",
                  "sort": "accessed_on"}, title: "${_('Accessed on')}", className: "td-time" },
         { data: {"_": "action",
                  "sort": "action"}, title: "${_('Action')}", className: "td-action", orderable: false }
      ],
      language: {
          paginate: DEFAULT_GRID_PAGINATION,
          sProcessing: _gettext('loading...'),
          emptyTable: _gettext("No ssh keys available yet.")
      },

      "createdRow": function ( row, data, index ) {
          if (!data['active_raw']){
            $(row).addClass('closed')
          }
      }
    });

    $sshKeyListTable.on('xhr.dt', function(e, settings, json, xhr){
        $sshKeyListTable.css('opacity', 1);
    });

    $sshKeyListTable.on('preXhr.dt', function(e, settings, data){
        $sshKeyListTable.css('opacity', 0.3);
    });

    // filter
    $('#q_filter').on('keyup',
        $.debounce(250, function() {
            $sshKeyListTable.DataTable().search(
                $('#q_filter').val()
            ).draw();
        })
    );

  });
</script>
