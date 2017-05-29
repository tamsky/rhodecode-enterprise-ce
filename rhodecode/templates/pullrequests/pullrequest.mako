<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${c.repo_name} ${_('New pull request')}
</%def>

<%def name="breadcrumbs_links()">
    ${_('New pull request')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='repositories')}
</%def>

<%def name="menu_bar_subnav()">
    ${self.repo_menu(active='showpullrequest')}
</%def>

<%def name="main()">
<div class="box">
    <div class="title">
        ${self.repo_page_title(c.rhodecode_db_repo)}
        ${self.breadcrumbs()}
    </div>

    ${h.secure_form(url('pullrequest', repo_name=c.repo_name), method='post', id='pull_request_form')}
        <div class="box pr-summary">

            <div class="summary-details block-left">

                <div class="form">
                    <!-- fields -->

                    <div class="fields" >

                         <div class="field">
                            <div class="label">
                                <label for="pullrequest_title">${_('Title')}:</label>
                            </div>
                            <div class="input">
                                ${h.text('pullrequest_title', c.default_title, class_="medium autogenerated-title")}
                            </div>
                         </div>

                        <div class="field">
                            <div class="label label-textarea">
                                <label for="pullrequest_desc">${_('Description')}:</label>
                            </div>
                            <div class="textarea text-area editor">
                                ${h.textarea('pullrequest_desc',size=30, )}
                                <span class="help-block">${_('Write a short description on this pull request')}</span>
                            </div>
                        </div>

                        <div class="field">
                            <div class="label label-textarea">
                                <label for="pullrequest_desc">${_('Commit flow')}:</label>
                            </div>

                            ## TODO: johbo: Abusing the "content" class here to get the
                            ## desired effect. Should be replaced by a proper solution.

                            ##ORG
                            <div class="content">
                                <strong>${_('Source repository')}:</strong>
                                ${c.rhodecode_db_repo.description}
                            </div>
                            <div class="content">
                                ${h.hidden('source_repo')}
                                ${h.hidden('source_ref')}
                            </div>

                            ##OTHER, most Probably the PARENT OF THIS FORK
                            <div class="content">
                                ## filled with JS
                                <div id="target_repo_desc"></div>
                            </div>

                            <div class="content">
                                ${h.hidden('target_repo')}
                                ${h.hidden('target_ref')}
                                <span id="target_ref_loading" style="display: none">
                                    ${_('Loading refs...')}
                                </span>
                            </div>
                        </div>

                        <div class="field">
                            <div class="label label-textarea">
                                <label for="pullrequest_submit"></label>
                            </div>
                            <div class="input">
                                <div class="pr-submit-button">
                                    ${h.submit('save',_('Submit Pull Request'),class_="btn")}
                                </div>
                                <div id="pr_open_message"></div>
                            </div>
                        </div>

                        <div class="pr-spacing-container"></div>
                    </div>
                </div>
            </div>
            <div>
                ## REIEW RULES
                <div id="review_rules" style="display: none" class="reviewers-title block-right">
                    <div class="pr-details-title">
                        ${_('Reviewer rules')}
                    </div>
                    <div class="pr-reviewer-rules">
                        ## review rules will be appended here, by default reviewers logic
                    </div>
                </div>

                ## REVIEWERS
                <div class="reviewers-title block-right">
                    <div class="pr-details-title">
                        ${_('Pull request reviewers')}
                        <span class="calculate-reviewers"> - ${_('loading...')}</span>
                    </div>
                </div>
                <div id="reviewers" class="block-right pr-details-content reviewers">
                    ## members goes here, filled via JS based on initial selection !
                    <input type="hidden" name="__start__" value="review_members:sequence">
                    <ul id="review_members" class="group_members"></ul>
                    <input type="hidden" name="__end__" value="review_members:sequence">
                    <div id="add_reviewer_input" class='ac'>
                        <div class="reviewer_ac">
                            ${h.text('user', class_='ac-input', placeholder=_('Add reviewer or reviewer group'))}
                            <div id="reviewers_container"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="box">
            <div>
                ## overview pulled by ajax
                <div id="pull_request_overview"></div>
            </div>
        </div>
    ${h.end_form()}
</div>

<script type="text/javascript">
$(function(){
  var defaultSourceRepo = '${c.default_repo_data['source_repo_name']}';
  var defaultSourceRepoData = ${c.default_repo_data['source_refs_json']|n};
  var defaultTargetRepo = '${c.default_repo_data['target_repo_name']}';
  var defaultTargetRepoData = ${c.default_repo_data['target_refs_json']|n};

  var $pullRequestForm = $('#pull_request_form');
  var $sourceRepo = $('#source_repo', $pullRequestForm);
  var $targetRepo = $('#target_repo', $pullRequestForm);
  var $sourceRef = $('#source_ref', $pullRequestForm);
  var $targetRef = $('#target_ref', $pullRequestForm);

  var sourceRepo = function() { return $sourceRepo.eq(0).val() };
  var sourceRef = function() { return $sourceRef.eq(0).val().split(':') };

  var targetRepo = function() { return $targetRepo.eq(0).val() };
  var targetRef = function() { return $targetRef.eq(0).val().split(':') };

  var calculateContainerWidth = function() {
      var maxWidth = 0;
      var repoSelect2Containers = ['#source_repo', '#target_repo'];
      $.each(repoSelect2Containers, function(idx, value) {
          $(value).select2('container').width('auto');
          var curWidth = $(value).select2('container').width();
          if (maxWidth <= curWidth) {
              maxWidth = curWidth;
          }
          $.each(repoSelect2Containers, function(idx, value) {
              $(value).select2('container').width(maxWidth + 10);
          });
      });
  };

  var initRefSelection = function(selectedRef) {
      return function(element, callback) {
          // translate our select2 id into a text, it's a mapping to show
          // simple label when selecting by internal ID.
          var id, refData;
          if (selectedRef === undefined) {
            id = element.val();
            refData = element.val().split(':');
          } else {
            id = selectedRef;
            refData = selectedRef.split(':');
          }

          var text = refData[1];
          if (refData[0] === 'rev') {
              text = text.substring(0, 12);
          }

          var data = {id: id, text: text};

          callback(data);
      };
  };

  var formatRefSelection = function(item) {
      var prefix = '';
      var refData = item.id.split(':');
      if (refData[0] === 'branch') {
          prefix = '<i class="icon-branch"></i>';
      }
      else if (refData[0] === 'book') {
          prefix = '<i class="icon-bookmark"></i>';
      }
      else if (refData[0] === 'tag') {
          prefix = '<i class="icon-tag"></i>';
      }

      var originalOption = item.element;
      return prefix + item.text;
  };

  // custom code mirror
  var codeMirrorInstance = initPullRequestsCodeMirror('#pullrequest_desc');

  reviewersController = new ReviewersController();

  var queryTargetRepo = function(self, query) {
      // cache ALL results if query is empty
      var cacheKey = query.term || '__';
      var cachedData = self.cachedDataSource[cacheKey];

      if (cachedData) {
          query.callback({results: cachedData.results});
      } else {
          $.ajax({
              url: pyroutes.url('pullrequest_repo_destinations', {'repo_name': templateContext.repo_name}),
              data: {query: query.term},
              dataType: 'json',
              type: 'GET',
              success: function(data) {
                  self.cachedDataSource[cacheKey] = data;
                  query.callback({results: data.results});
              },
              error: function(data, textStatus, errorThrown) {
                  alert(
                    "Error while fetching entries.\nError code {0} ({1}).".format(data.status, data.statusText));
              }
          });
      }
  };

  var queryTargetRefs = function(initialData, query) {
      var data = {results: []};
      // filter initialData
      $.each(initialData, function() {
          var section = this.text;
          var children = [];
          $.each(this.children, function() {
              if (query.term.length === 0 ||
                  this.text.toUpperCase().indexOf(query.term.toUpperCase()) >= 0 ) {
                  children.push({'id': this.id, 'text': this.text})
              }
          });
          data.results.push({'text': section, 'children': children})
      });
      query.callback({results: data.results});
  };

  var loadRepoRefDiffPreview = function() {

      var url_data = {
          'repo_name': targetRepo(),
          'target_repo': sourceRepo(),
          'source_ref': targetRef()[2],
          'source_ref_type': 'rev',
          'target_ref': sourceRef()[2],
          'target_ref_type': 'rev',
          'merge': true,
          '_': Date.now() // bypass browser caching
      }; // gather the source/target ref and repo here

      if (sourceRef().length !== 3 || targetRef().length !== 3) {
          prButtonLock(true, "${_('Please select source and target')}");
          return;
      }
      var url = pyroutes.url('compare_url', url_data);

      // lock PR button, so we cannot send PR before it's calculated
      prButtonLock(true, "${_('Loading compare ...')}", 'compare');

      if (loadRepoRefDiffPreview._currentRequest) {
          loadRepoRefDiffPreview._currentRequest.abort();
      }

      loadRepoRefDiffPreview._currentRequest = $.get(url)
          .error(function(data, textStatus, errorThrown) {
                alert(
                "Error while processing request.\nError code {0} ({1}).".format(
                        data.status, data.statusText));
          })
          .done(function(data) {
              loadRepoRefDiffPreview._currentRequest = null;
              $('#pull_request_overview').html(data);

              var commitElements = $(data).find('tr[commit_id]');

              var prTitleAndDesc = getTitleAndDescription(
                  sourceRef()[1], commitElements, 5);

              var title = prTitleAndDesc[0];
              var proposedDescription = prTitleAndDesc[1];

              var useGeneratedTitle = (
                   $('#pullrequest_title').hasClass('autogenerated-title') ||
                   $('#pullrequest_title').val() === "");

              if (title && useGeneratedTitle) {
                  // use generated title if we haven't specified our own
                  $('#pullrequest_title').val(title);
                  $('#pullrequest_title').addClass('autogenerated-title');

              }

              var useGeneratedDescription = (
                  !codeMirrorInstance._userDefinedDesc ||
                   codeMirrorInstance.getValue() === "");

              if (proposedDescription && useGeneratedDescription) {
                  // set proposed content, if we haven't defined our own,
                  // or we don't have description written
                  codeMirrorInstance._userDefinedDesc = false; // reset state
                  codeMirrorInstance.setValue(proposedDescription);
              }

              var msg = '';
              if (commitElements.length === 1) {
                  msg = "${ungettext('This pull request will consist of __COMMITS__ commit.', 'This pull request will consist of __COMMITS__ commits.', 1)}";
              } else {
                  msg = "${ungettext('This pull request will consist of __COMMITS__ commit.', 'This pull request will consist of __COMMITS__ commits.', 2)}";
              }

              msg += ' <a id="pull_request_overview_url" href="{0}" target="_blank">${_('Show detailed compare.')}</a>'.format(url);

              if (commitElements.length) {
                  var commitsLink = '<a href="#pull_request_overview"><strong>{0}</strong></a>'.format(commitElements.length);
                  prButtonLock(false, msg.replace('__COMMITS__', commitsLink), 'compare');
              }
              else {
                  prButtonLock(true, "${_('There are no commits to merge.')}", 'compare');
              }


          });
  };

  var Select2Box = function(element, overrides) {
    var globalDefaults = {
        dropdownAutoWidth: true,
        containerCssClass: "drop-menu",
        dropdownCssClass: "drop-menu-dropdown"
    };

    var initSelect2 = function(defaultOptions) {
      var options = jQuery.extend(globalDefaults, defaultOptions, overrides);
      element.select2(options);
    };

    return {
      initRef: function() {
        var defaultOptions = {
          minimumResultsForSearch: 5,
          formatSelection: formatRefSelection
        };

        initSelect2(defaultOptions);
      },

      initRepo: function(defaultValue, readOnly) {
        var defaultOptions = {
          initSelection : function (element, callback) {
            var data = {id: defaultValue, text: defaultValue};
            callback(data);
          }
        };

        initSelect2(defaultOptions);

        element.select2('val', defaultSourceRepo);
        if (readOnly === true) {
          element.select2('readonly', true);
        }
      }
    };
  };

  var initTargetRefs = function(refsData, selectedRef){
    Select2Box($targetRef, {
      query: function(query) {
        queryTargetRefs(refsData, query);
      },
      initSelection : initRefSelection(selectedRef)
    }).initRef();

    if (!(selectedRef === undefined)) {
        $targetRef.select2('val', selectedRef);
    }
  };

  var targetRepoChanged = function(repoData) {
      // generate new DESC of target repo displayed next to select
      $('#target_repo_desc').html(
          "<strong>${_('Target repository')}</strong>: {0}".format(repoData['description'])
      );

      // generate dynamic select2 for refs.
      initTargetRefs(repoData['refs']['select2_refs'],
                     repoData['refs']['selected_ref']);

  };

  var sourceRefSelect2 = Select2Box($sourceRef, {
      placeholder: "${_('Select commit reference')}",
      query: function(query) {
        var initialData = defaultSourceRepoData['refs']['select2_refs'];
        queryTargetRefs(initialData, query)
      },
      initSelection: initRefSelection()
    }
  );

  var sourceRepoSelect2 = Select2Box($sourceRepo, {
    query: function(query) {}
  });

  var targetRepoSelect2 = Select2Box($targetRepo, {
    cachedDataSource: {},
    query: $.debounce(250, function(query) {
      queryTargetRepo(this, query);
    }),
    formatResult: formatResult
  });

  sourceRefSelect2.initRef();

  sourceRepoSelect2.initRepo(defaultSourceRepo, true);

  targetRepoSelect2.initRepo(defaultTargetRepo, false);

  $sourceRef.on('change', function(e){
    loadRepoRefDiffPreview();
    reviewersController.loadDefaultReviewers(
        sourceRepo(), sourceRef(), targetRepo(), targetRef());
  });

  $targetRef.on('change', function(e){
    loadRepoRefDiffPreview();
    reviewersController.loadDefaultReviewers(
        sourceRepo(), sourceRef(), targetRepo(), targetRef());
  });

  $targetRepo.on('change', function(e){
      var repoName = $(this).val();
      calculateContainerWidth();
      $targetRef.select2('destroy');
      $('#target_ref_loading').show();

      $.ajax({
          url: pyroutes.url('pullrequest_repo_refs',
            {'repo_name': templateContext.repo_name, 'target_repo_name':repoName}),
          data: {},
          dataType: 'json',
          type: 'GET',
          success: function(data) {
              $('#target_ref_loading').hide();
              targetRepoChanged(data);
              loadRepoRefDiffPreview();
          },
          error: function(data, textStatus, errorThrown) {
              alert("Error while fetching entries.\nError code {0} ({1}).".format(data.status, data.statusText));
          }
      })

  });

  prButtonLock(true, "${_('Please select source and target')}", 'all');

  // auto-load on init, the target refs select2
  calculateContainerWidth();
  targetRepoChanged(defaultTargetRepoData);

  $('#pullrequest_title').on('keyup', function(e){
      $(this).removeClass('autogenerated-title');
  });

  % if c.default_source_ref:
  // in case we have a pre-selected value, use it now
  $sourceRef.select2('val', '${c.default_source_ref}');
  loadRepoRefDiffPreview();
  reviewersController.loadDefaultReviewers(
      sourceRepo(), sourceRef(), targetRepo(), targetRef());
  % endif

  ReviewerAutoComplete('#user');
});
</script>

</%def>
