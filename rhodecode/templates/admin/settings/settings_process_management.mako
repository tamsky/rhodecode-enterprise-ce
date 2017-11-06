
<div id="update_notice" style="display: none; margin: -40px 0px 20px 0px">
    <div>${_('Checking for updates...')}</div>
</div>


<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Gunicorn process management')}</h3>

    </div>
    <div class="panel-body" id="app">
        <h3>List of Gunicorn processes on this machine</h3>
        <%
            def get_name(proc):
                cmd = ' '.join(proc.cmdline())
                if 'vcsserver.ini' in cmd:
                    return 'VCSServer'
                elif 'rhodecode.ini' in cmd:
                    return 'RhodeCode'
                return proc.name()
        %>
        <table>
        % for proc in c.gunicorn_processes:
            <% mem = proc.memory_info()%>
            <% children = proc.children(recursive=True) %>
            % if children:

            <tr>
                <td>
                    <code>
                    ${proc.pid} - ${get_name(proc)}
                    </code>
                </td>
                <td>
                    <a href="#showCommand" onclick="$('#pid'+${proc.pid}).toggle();return false"> command </a>
                    <code id="pid${proc.pid}" style="display: none">
                    ${' '.join(proc.cmdline())}
                    </code>
                </td>
                <td></td>
                <td>
                    RSS:${h.format_byte_size_binary(mem.rss)}
                </td>
                <td>
                    VMS:${h.format_byte_size_binary(mem.vms)}
                </td>
                <td>
                    AGE: ${h.age_component(h.time_to_utcdatetime(proc.create_time()))}
                </td>
                <td>
                    MASTER
                </td>
            </tr>
            <% mem_sum = 0 %>
            % for proc_child in children:
                <% mem = proc_child.memory_info()%>
                <tr>
                    <td>
                        <code>
                          | ${proc_child.pid} - ${get_name(proc_child)}
                        </code>
                    </td>
                    <td>
                        <a href="#showCommand" onclick="$('#pid'+${proc_child.pid}).toggle();return false"> command </a>
                        <code id="pid${proc_child.pid}" style="display: none">
                        ${' '.join(proc_child.cmdline())}
                        </code>
                    </td>
                    <td>
                        CPU: ${proc_child.cpu_percent()} %
                    </td>
                    <td>
                        RSS:${h.format_byte_size_binary(mem.rss)}
                        <% mem_sum += mem.rss %>
                    </td>
                    <td>
                        VMS:${h.format_byte_size_binary(mem.vms)}
                    </td>
                    <td>
                        AGE: ${h.age_component(h.time_to_utcdatetime(proc_child.create_time()))}
                    </td>
                    <td>
                        <a href="#restartProcess" onclick="restart(this, ${proc_child.pid});return false">
                            restart
                        </a>
                    </td>
                </tr>
            % endfor
            <tr>
                <td colspan="2"><code>| total processes: ${len(children)}</code></td>
                <td></td>
                <td><strong>RSS:${h.format_byte_size_binary(mem_sum)}</strong></td>
                <td></td>
            </tr>
            <tr><td> <code> -- </code> </td></tr>

            % endif
        % endfor
        </table>
    </div>
</div>


<script>


restart = function(elem, pid) {

    if ($(elem).hasClass('disabled')){
        return;
    }
    $(elem).addClass('disabled');
    $(elem).html('processing...');

    $.ajax({
        url: pyroutes.url('admin_settings_process_management_signal'),
        headers: {
            "X-CSRF-Token": CSRF_TOKEN,
        },
        data: JSON.stringify({'pids': [pid]}),
        dataType: 'json',
        type: 'POST',
        contentType: "application/json; charset=utf-8",
        success: function (data) {
            $(elem).html(data.result);
            $(elem).removeClass('disabled');
        },
        failure: function (data) {
            $(elem).text('FAILED TO LOAD RESULT');
            $(elem).removeClass('disabled');
        },
        error: function (data) {
            $(elem).text('FAILED TO LOAD RESULT');
            $(elem).removeClass('disabled');
        }
    })
}


</script>
