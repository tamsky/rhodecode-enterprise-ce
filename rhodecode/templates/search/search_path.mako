<%namespace name="search" file="/search/search.mako"/>

% if c.formatted_results:

<table class="rctable search-results">
    <tr>
        <th>${_('Repository')}</th>
        <th>${_('File')}</th>
        <th>${_('Size')}</th>
        <th>${_('Lines')}</th>
    </tr>
    %for entry in c.formatted_results:
        ## search results are additionally filtered, and this check is just a safe gate
        % if c.rhodecode_user.is_admin or h.HasRepoPermissionAny('repository.write','repository.read','repository.admin')(entry['repository'], 'search results path check'):
            <tr class="body">
                <td class="td-componentname">
                    <% repo_type = entry.get('repo_type') or h.get_repo_type_by_name(entry.get('repository')) %>
                    ${search.repo_icon(repo_type)}
                    ${h.link_to(entry['repository'], h.route_path('repo_summary',repo_name=entry['repository']))}
                </td>
                <td class="td-componentname">
                    ${h.link_to(h.literal(entry['f_path']),
                        h.route_path('repo_files',repo_name=entry['repository'],commit_id='tip',f_path=entry['f_path']))}
                </td>
                <td>
                    %if entry.get('size'):
                      ${h.format_byte_size_binary(entry['size'])}
                    %endif
                </td>
                <td>
                    %if entry.get('lines'):
                      ${entry.get('lines', 0.)} ${_ungettext('line', 'lines', entry.get('lines', 0.))}
                    %endif
                </td>
            </tr>
        % endif
    %endfor
</table>

%if c.cur_query:
<div class="pagination-wh pagination-left">
    ${c.formatted_results.pager('$link_previous ~2~ $link_next')}
</div>
%endif

% endif
