<%def name="title(*args)">
    ${_('%s Files') % c.repo_name}
    %if hasattr(c,'file'):
        &middot; ${h.safe_unicode(c.file.path) or '\\'}
    %endif

    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<div id="pjax-content" data-title="${self.title()}">
    <div class="summary-detail">
        <div class="summary-detail-header">
            <div class="breadcrumbs files_location">
                <h4>
                    ${_('Location')}: ${h.files_breadcrumbs(c.repo_name,c.commit.raw_id,c.file.path)}
                    %if c.annotate:
                    - ${_('annotation')}
                    %endif
                </h4>
            </div>
            <div  class="btn-collapse" data-toggle="summary-details">
                ${_('Show More')}
            </div>
        </div><!--end summary-detail-header-->

        % if c.file.is_submodule():
            <span class="submodule-dir">Submodule ${h.escape(c.file.name)}</span>
        % elif c.file.is_dir():
            <%include file='file_tree_detail.mako'/>
        % else:
            <%include file='files_detail.mako'/>
        % endif

    </div> <!--end summary-detail-->
    <script>
        // set the pageSource variable
        var fileSourcePage = ${c.file_source_page};
    </script>
    % if c.file.is_dir():
        <div id="commit-stats" class="sidebar-right">
            <%include file='file_tree_author_box.mako'/>
        </div>

        <%include file='files_browser.mako'/>
    % else:
        <div id="file_authors" class="sidebar-right">
            <%include file='file_authors_box.mako'/>
        </div>

        <%include file='files_source.mako'/>
    % endif

</div>