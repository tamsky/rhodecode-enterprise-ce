
<div id="codeblock" class="browserblock">
    <div class="browser-header">
        <div class="browser-nav">
            ${h.form(h.current_route_path(request), method='GET', id='at_rev_form')}
            <div class="info_box">
              ${h.hidden('refs_filter')}
              <div class="info_box_elem previous">
                    <a id="prev_commit_link" data-commit-id="${c.prev_commit.raw_id}" class="pjax-link ${'disabled' if c.url_prev == '#' else ''}" href="${c.url_prev}" title="${_('Previous commit')}"><i class="icon-left"></i></a>
              </div>
              <div class="info_box_elem">${h.text('at_rev',value=c.commit.idx)}</div>
              <div class="info_box_elem next">
                    <a id="next_commit_link" data-commit-id="${c.next_commit.raw_id}" class="pjax-link ${'disabled' if c.url_next == '#' else ''}" href="${c.url_next}" title="${_('Next commit')}"><i class="icon-right"></i></a>
              </div>
            </div>
            ${h.end_form()}

            <div id="search_activate_id" class="search_activate">
               <a class="btn btn-default" id="filter_activate" href="javascript:void(0)">${_('Search File List')}</a>
            </div>
            <div id="search_deactivate_id"  class="search_activate hidden">
               <a class="btn btn-default" id="filter_deactivate" href="javascript:void(0)">${_('Close File List')}</a>
            </div>
            % if h.HasRepoPermissionAny('repository.write','repository.admin')(c.repo_name):
              <div title="${_('Add New File')}" class="btn btn-primary new-file">
                <a href="${h.route_path('repo_files_add_file',repo_name=c.repo_name,commit_id=c.commit.raw_id,f_path=c.f_path, _anchor='edit')}">
                    ${_('Add File')}</a>
              </div>
            % endif
            % if c.enable_downloads:
              <% at_path = '{}.zip'.format(request.GET.get('at') or c.commit.raw_id[:6]) %>
              <div title="${_('Download tree at {}').format(at_path)}" class="btn btn-default new-file">
                <a href="${h.route_path('repo_archivefile',repo_name=c.repo_name, fname=c.commit.raw_id)}">
                    ${_('Download tree at {}').format(at_path)}
                </a>
              </div>
            % endif
        </div>

        <div class="browser-search">
            <div class="node-filter">
                <div class="node_filter_box hidden" id="node_filter_box_loading" >${_('Loading file list...')}</div>
                <div class="node_filter_box hidden" id="node_filter_box" >
                    <div class="node-filter-path">${h.get_last_path_part(c.file)}/</div>
                    <div class="node-filter-input">
                        <input class="init" type="text" name="filter" size="25" id="node_filter" autocomplete="off">
                    </div>
                </div>
            </div>
        </div>
    </div>
    ## file tree is computed from caches, and filled in
    <div id="file-tree">
    ${c.file_tree |n}
    </div>

</div>
