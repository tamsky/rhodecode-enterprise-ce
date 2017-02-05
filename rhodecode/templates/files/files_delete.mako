<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('%s Files Delete') % c.repo_name}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>

<%def name="breadcrumbs_links()">
    ${_('Delete file')} @ ${h.show_id(c.commit)}
</%def>

<%def name="menu_bar_subnav()">
    ${self.repo_menu(active='files')}
</%def>

<%def name="main()">
<div class="box">
    <div class="title">
        ${self.repo_page_title(c.rhodecode_db_repo)}
    </div>
    <div class="edit-file-title">
        ${self.breadcrumbs()}
    </div>
    ${h.secure_form(h.url.current(),method='post',class_="form-horizontal")}
    <div class="edit-file-fieldset">
        <div class="fieldset">
            <div id="destination-label" class="left-label">
                ${_('Path')}:
            </div>
            <div class="right-content">
                <span id="path-breadcrumbs">${h.files_breadcrumbs(c.repo_name,c.commit.raw_id,c.f_path)}</span>
            </div>
        </div>
    </div>

    <div id="codeblock" class="codeblock delete-file-preview">
        <div class="code-body">
            %if c.file.is_binary:
                ${_('Binary file (%s)') % c.file.mimetype}
            %else:
                %if c.file.size < c.cut_off_limit:
                    ${h.pygmentize(c.file,linenos=True,anchorlinenos=False,cssclass="code-highlight")}
                %else:
                    ${_('File is too big to display')} ${h.link_to(_('Show as raw'),
                    h.url('files_raw_home',repo_name=c.repo_name,revision=c.commit.raw_id,f_path=c.f_path))}
                %endif
            %endif
        </div>
    </div>

    <div class="edit-file-fieldset">
        <div class="fieldset">
            <div id="commit-message-label" class="commit-message-label left-label">
                ${_('Commit Message')}:
            </div>
            <div class="right-content">
                <div class="message">
                    <textarea id="commit" name="message"  placeholder="${c.default_message}"></textarea>
                </div>
            </div>
        </div>
        <div class="pull-right">
            ${h.reset('reset',_('Cancel'),class_="btn btn-small btn-danger")}
            ${h.submit('commit',_('Delete File'),class_="btn btn-small btn-danger-action")}
        </div>
    </div>
    ${h.end_form()}
</div>
</%def>
