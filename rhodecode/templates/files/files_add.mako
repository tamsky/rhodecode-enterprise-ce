<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('%s Files Add') % c.repo_name}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>

<%def name="breadcrumbs_links()">
    ${_('Add new file')} @ ${h.show_id(c.commit)}
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
    ${h.secure_form(h.route_path('repo_files_create_file', repo_name=c.repo_name, commit_id=c.commit.raw_id, f_path=c.f_path), id='eform', method='POST', enctype="multipart/form-data", class_="form-horizontal", request=request)}
    <div class="edit-file-fieldset">
        <div class="fieldset">
            <div id="destination-label" class="left-label">
                ${_('Path')}:
            </div>
            <div class="right-content">
                <div id="specify-custom-path-container">
                    <span id="path-breadcrumbs">${h.files_breadcrumbs(c.repo_name,c.commit.raw_id,c.f_path)}</span>
                    <a class="custom-path-link" id="specify-custom-path" href="#">${_('Specify Custom Path')}</a>
                </div>
                <div id="remove-custom-path-container" style="display: none;">
                    ${c.repo_name}/
                    <input type="input-small" value="${c.f_path}" size="46" name="location" id="location">
                    <a class="custom-path-link" id="remove-custom-path" href="#">${_('Remove Custom Path')}</a>
                </div>
            </div>
        </div>
        <div id="filename_container" class="fieldset">
            <div class="filename-label left-label">
                ${_('Filename')}:
            </div>
            <div class="right-content">
                <input class="input-small" type="text" value="" size="46" name="filename" id="filename">
                <p>${_('or')} <a id="upload_file_enable" href="#">${_('Upload File')}</a></p>
            </div>
        </div>
        <div id="upload_file_container" class="fieldset" style="display: none;">
            <div class="filename-label left-label">
                ${_('Filename')}:
            </div>
            <div class="right-content">
                <input class="input-small" type="text" value="" size="46" name="filename_upload" id="filename_upload" placeholder="${_('No file selected')}">
            </div>
            <div class="filename-label left-label file-upload-label">
                ${_('Upload file')}:
            </div>
            <div class="right-content file-upload-input">
                <label for="upload_file" class="btn btn-default">Browse</label>

                <input type="file" name="upload_file" id="upload_file">
                <p>${_('or')} <a id="file_enable" href="#">${_('Create New File')}</a></p>
            </div>
        </div>
    </div>
    <div class="table">
        <div id="files_data">
            <div id="codeblock" class="codeblock">
            <div class="code-header form" id="set_mode_header">
                <div class="fields">
                    ${h.dropdownmenu('set_mode','plain',[('plain',_('plain'))],enable_filter=True)}
                    <label for="line_wrap">${_('line wraps')}</label>
                    ${h.dropdownmenu('line_wrap', 'off', [('on', _('on')), ('off', _('off')),])}

                    <div id="render_preview" class="btn btn-small preview hidden" >${_('Preview')}</div>
                </div>
            </div>
                <div id="editor_container">
                    <pre id="editor_pre"></pre>
                    <textarea id="editor" name="content" ></textarea>
                    <div id="editor_preview"></div>
                </div>
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
                    <textarea id="commit" name="message"  placeholder="${c.default_message}"></textarea>
                </div>
            </div>
        </div>
        <div class="pull-right">
            ${h.reset('reset',_('Cancel'),class_="btn btn-small")}
            ${h.submit('commit_btn',_('Commit changes'),class_="btn btn-small btn-success")}
        </div>
    </div>
    ${h.end_form()}
</div>
<script type="text/javascript">

    $('#commit_btn').on('click', function() {
        var button = $(this);
        if (button.hasClass('clicked')) {
            button.attr('disabled', true);
        } else {
            button.addClass('clicked');
        }
    });
    
    $('#specify-custom-path').on('click', function(e){
        e.preventDefault();
        $('#specify-custom-path-container').hide();
        $('#remove-custom-path-container').show();
        $('#destination-label').css('margin-top', '13px');
    });

    $('#remove-custom-path').on('click', function(e){
        e.preventDefault();
        $('#specify-custom-path-container').show();
        $('#remove-custom-path-container').hide();
        $('#location').val('${c.f_path}');
        $('#destination-label').css('margin-top', '0');
    });

    var hide_upload = function(){
        $('#files_data').show();
        $('#upload_file_container').hide();
        $('#filename_container').show();
    };

    $('#file_enable').on('click', function(e){
        e.preventDefault();
        hide_upload();
    });

    $('#upload_file_enable').on('click', function(e){
        e.preventDefault();
        $('#files_data').hide();
        $('#upload_file_container').show();
        $('#filename_container').hide();
        if (detectIE() && detectIE() <= 9) {
            $('#upload_file_container .file-upload-input label').hide();
            $('#upload_file_container .file-upload-input span').hide();
            $('#upload_file_container .file-upload-input input').show();
        }
    });

    $('#upload_file').on('change', function() {
        if (this.files && this.files[0]) {
            $('#filename_upload').val(this.files[0].name);
        }
    });

    hide_upload();

    var renderer = "";
    var reset_url = "${h.route_path('repo_files',repo_name=c.repo_name,commit_id=c.commit.raw_id,f_path=c.f_path)}";
    var myCodeMirror = initCodeMirror('editor', reset_url, false);

    var modes_select = $('#set_mode');
    fillCodeMirrorOptions(modes_select);

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
    $('#filename').focus();

</script>
</%def>
