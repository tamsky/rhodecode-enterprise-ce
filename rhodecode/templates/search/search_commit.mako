<%namespace name="base" file="/base/base.mako"/>

<table class="rctable search-results">
    <tr>
        <th>${_('Repository')}</th>
        <th>${_('Commit')}</th>
        <th></th>
        <th>${_('Commit message')}</th>
        <th>
        %if c.sort == 'newfirst':
            <a href="${c.url_generator(sort='oldfirst')}">${_('Age (new first)')}</a>
        %else:
            <a href="${c.url_generator(sort='newfirst')}">${_('Age (old first)')}</a>
        %endif
        </th>
        <th>${_('Author')}</th>
    </tr>
    %for entry in c.formatted_results:
        ## search results are additionally filtered, and this check is just a safe gate
        % if h.HasRepoPermissionAny('repository.write','repository.read','repository.admin')(entry['repository'], 'search results commit check'):
            <tr class="body">
                <td class="td-componentname">
                    %if h.get_repo_type_by_name(entry.get('repository')) == 'hg':
                        <i class="icon-hg"></i>
                    %elif h.get_repo_type_by_name(entry.get('repository')) == 'git':
                        <i class="icon-git"></i>
                    %elif h.get_repo_type_by_name(entry.get('repository')) == 'svn':
                        <i class="icon-svn"></i>
                    %endif
                    ${h.link_to(entry['repository'], h.route_path('repo_summary',repo_name=entry['repository']))}
                </td>
                <td class="td-commit">
                    ${h.link_to(h._shorten_commit_id(entry['commit_id']),
                      h.route_path('repo_commit',repo_name=entry['repository'],commit_id=entry['commit_id']))}
                </td>
                <td class="td-message expand_commit search open" data-commit-id="${h.md5_safe(entry['repository'])+entry['commit_id']}" id="t-${h.md5_safe(entry['repository'])+entry['commit_id']}" title="${_('Expand commit message')}">
                    <div class="show_more_col">
                    <i class="icon-expand-linked"></i>&nbsp;
                    </div>
                </td>
                <td data-commit-id="${h.md5_safe(entry['repository'])+entry['commit_id']}" id="c-${h.md5_safe(entry['repository'])+entry['commit_id']}" class="message td-description open">
                    %if entry.get('message_hl'):
                        ${h.literal(entry['message_hl'])}
                    %else:
                        ${h.urlify_commit_message(entry['message'], entry['repository'])}
                    %endif
                </td>
                <td class="td-time">
                    ${h.age_component(h.time_to_utcdatetime(entry['date']))}
                </td>

                <td class="td-user author">
                    ${base.gravatar_with_user(entry['author'])}
                </td>
            </tr>
        % endif
    %endfor
</table>

%if c.cur_query and c.formatted_results:
<div class="pagination-wh pagination-left">
    ${c.formatted_results.pager('$link_previous ~2~ $link_next')}
</div>
%endif

<script>
    $('.expand_commit').on('click',function(e){
      var target_expand = $(this);
      var cid = target_expand.data('commit-id');

      if (target_expand.hasClass('open')){
        $('#c-'+cid).css({'height': '1.5em', 'white-space': 'nowrap', 'text-overflow': 'ellipsis', 'overflow':'hidden'})
        $('#t-'+cid).css({'height': 'auto', 'line-height': '.9em', 'text-overflow': 'ellipsis', 'overflow':'hidden'})
        target_expand.removeClass('open');
      }
      else {
        $('#c-'+cid).css({'height': 'auto', 'white-space': 'normal', 'text-overflow': 'initial', 'overflow':'visible'})
        $('#t-'+cid).css({'height': 'auto', 'max-height': 'none', 'text-overflow': 'initial', 'overflow':'visible'})
        target_expand.addClass('open');
      }
    });
</script>
