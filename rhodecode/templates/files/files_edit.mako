<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('%s File Edit') % c.repo_name}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>

<%def name="breadcrumbs_links()">
    ${_('Edit file')} @ ${h.show_id(c.commit)}
</%def>

<%def name="menu_bar_subnav()">
    ${self.repo_menu(active='files')}
</%def>

<%def name="main()">
<% renderer = h.renderer_from_filename(c.f_path)%>
<div class="box">
    <div class="title">
        ${self.repo_page_title(c.rhodecode_db_repo)}
    </div>
    <div class="edit-file-title">
        ${self.breadcrumbs()}
    </div>
    <div class="edit-file-fieldset">
        <div class="fieldset">
            <div id="destination-label" class="left-label">
                ${_('Path')}:
            </div>
            <div class="right-content">
                <div id="specify-custom-path-container">
                    <span id="path-breadcrumbs">${h.files_breadcrumbs(c.repo_name,c.commit.raw_id,c.f_path)}</span>
                </div>
            </div>
        </div>
    </div>

    <div class="table">
        ${h.secure_form(h.route_path('repo_files_update_file', repo_name=c.repo_name, commit_id=c.commit.raw_id, f_path=c.f_path), id='eform', request=request)}
        <div id="codeblock" class="codeblock" >
        <div class="code-header">
            <div class="stats">
                <i class="icon-file"></i>
                <span class="item">${h.link_to("r%s:%s" % (c.file.commit.idx,h.short_id(c.file.commit.raw_id)),h.route_path('repo_commit',repo_name=c.repo_name,commit_id=c.file.commit.raw_id))}</span>
                <span class="item">${h.format_byte_size_binary(c.file.size)}</span>
                <span class="item last">${c.file.mimetype}</span>
                <div class="buttons">
                  <a class="btn btn-mini" href="${h.route_path('repo_changelog_file',repo_name=c.repo_name, commit_id=c.commit.raw_id, f_path=c.f_path)}">
                      <i class="icon-time"></i> ${_('history')}
                  </a>

                  % if h.HasRepoPermissionAny('repository.write','repository.admin')(c.repo_name):
                   % if not c.file.is_binary:
                      %if True:
                        ${h.link_to(_('source'),    h.route_path('repo_files',          repo_name=c.repo_name,commit_id=c.commit.raw_id,f_path=c.f_path),class_="btn btn-mini")}
                      %else:
                        ${h.link_to(_('annotation'),h.route_path('repo_files:annotated',repo_name=c.repo_name,commit_id=c.commit.raw_id,f_path=c.f_path),class_="btn btn-mini")}
                      %endif

                      <a class="btn btn-mini" href="${h.route_path('repo_file_raw',repo_name=c.repo_name,commit_id=c.commit.raw_id,f_path=c.f_path)}">
                          ${_('raw')}
                      </a>
                      <a class="btn btn-mini" href="${h.route_path('repo_file_download',repo_name=c.repo_name,commit_id=c.commit.raw_id,f_path=c.f_path)}">
                          <i class="icon-archive"></i> ${_('download')}
                      </a>
                   % endif
                  % endif
                </div>
            </div>
            <div class="form">
                <label for="set_mode">${_('Editing file')}:</label>
                ${'%s /' % c.file.dir_path if c.file.dir_path else c.file.dir_path}
                <input id="filename" type="text" name="filename" value="${c.file.name}">

                ${h.dropdownmenu('set_mode','plain',[('plain',_('plain'))],enable_filter=True)}
                <label for="line_wrap">${_('line wraps')}</label>
                ${h.dropdownmenu('line_wrap', 'off', [('on', _('on')), ('off', _('off')),])}

                <div id="render_preview" class="btn btn-small preview hidden">${_('Preview')}</div>
            </div>
        </div>
            <div id="editor_container">
                <pre id="editor_pre"></pre>
                <textarea id="editor" name="content" >${h.escape(c.file.content)|n}</textarea>
                <div id="editor_preview" ></div>
            </div>
        </div>
    </div>

    <div class="edit-file-fieldset">
        <div class="fieldset">
            <div id="commit-message-label" class="commit-message-label left-label">
                ${_('Commit Message')}:
            </div>
            <div class="right-content">
                <div class="message">
                    <textarea id="commit" name="message" placeholder="${c.default_message}"></textarea>
                </div>
            </div>
        </div>
        <div class="pull-right">
            ${h.reset('reset',_('Cancel'),class_="btn btn-small")}
            ${h.submit('commit',_('Commit changes'),class_="btn btn-small btn-success")}
        </div>
    </div>
    ${h.end_form()}
</div>

<script type="text/javascript">
$(document).ready(function(){
    var renderer = "${renderer}";
    var reset_url = "${h.route_path('repo_files',repo_name=c.repo_name,commit_id=c.commit.raw_id,f_path=c.file.path)}";
    var myCodeMirror = initCodeMirror('editor', reset_url);

    var modes_select = $('#set_mode');
    fillCodeMirrorOptions(modes_select);

    // try to detect the mode based on the file we edit
    var mimetype = "${c.file.mimetype}";
    var detected_mode = detectCodeMirrorMode(
            "${c.file.name}", mimetype);

    if(detected_mode){
        setCodeMirrorMode(myCodeMirror, detected_mode);
        $(modes_select).select2("val", mimetype);
        $(modes_select).change();
        setCodeMirrorMode(myCodeMirror, detected_mode);
    }

    var filename_selector = '#filename';
    var callback = function(filename, mimetype, mode){
        CodeMirrorPreviewEnable(mode);
    };
    // on change of select field set mode
    setCodeMirrorModeFromSelect(
            modes_select, filename_selector, myCodeMirror, callback);

    // on entering the new filename set mode, from given extension
    setCodeMirrorModeFromInput(
        modes_select, filename_selector, myCodeMirror, callback);

    // if the file is renderable set line wraps automatically
    if (renderer !== ""){
        var line_wrap = 'on';
        $($('#line_wrap option[value="'+line_wrap+'"]')[0]).attr("selected", "selected");
        setCodeMirrorLineWrap(myCodeMirror, true);
    }
    // on select line wraps change the editor
    $('#line_wrap').on('change', function(e){
        var selected = e.currentTarget;
        var line_wraps = {'on': true, 'off': false}[selected.value];
        setCodeMirrorLineWrap(myCodeMirror, line_wraps)
    });

    // render preview/edit button
    if (mimetype === 'text/x-rst' || mimetype === 'text/plain') {
        $('#render_preview').removeClass('hidden');
    }
    $('#render_preview').on('click', function(e){
        if($(this).hasClass('preview')){
            $(this).removeClass('preview');
            $(this).html("${_('Edit')}");
            $('#editor_preview').show();
            $(myCodeMirror.getWrapperElement()).hide();

            var possible_renderer = {
                'rst':'rst',
                'markdown':'markdown',
                'gfm': 'markdown'}[myCodeMirror.getMode().name];
            var _text = myCodeMirror.getValue();
            var _renderer = possible_renderer || DEFAULT_RENDERER;
            var post_data = {'text': _text, 'renderer': _renderer, 'csrf_token': CSRF_TOKEN};
            $('#editor_preview').html(_gettext('Loading ...'));
            var url = pyroutes.url('repo_commit_comment_preview',
                    {'repo_name': '${c.repo_name}',
                     'commit_id': '${c.commit.raw_id}'});
            ajaxPOST(url, post_data, function(o){
                $('#editor_preview').html(o);
            })
        }
        else{
            $(this).addClass('preview');
            $(this).html("${_('Preview')}");
            $('#editor_preview').hide();
            $(myCodeMirror.getWrapperElement()).show();
        }
    });

})
</script>
</%def>
