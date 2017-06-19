// # Copyright (C) 2010-2017 RhodeCode GmbH
// #
// # This program is free software: you can redistribute it and/or modify
// # it under the terms of the GNU Affero General Public License, version 3
// # (only), as published by the Free Software Foundation.
// #
// # This program is distributed in the hope that it will be useful,
// # but WITHOUT ANY WARRANTY; without even the implied warranty of
// # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// # GNU General Public License for more details.
// #
// # You should have received a copy of the GNU Affero General Public License
// # along with this program.  If not, see <http://www.gnu.org/licenses/>.
// #
// # This program is dual-licensed. If you wish to learn more about the
// # RhodeCode Enterprise Edition, including its added features, Support services,
// # and proprietary license terms, please see https://rhodecode.com/licenses/


var prButtonLockChecks = {
  'compare': false,
  'reviewers': false
};

/**
 * lock button until all checks and loads are made. E.g reviewer calculation
 * should prevent from submitting a PR
 * @param lockEnabled
 * @param msg
 * @param scope
 */
var prButtonLock = function(lockEnabled, msg, scope) {
      scope = scope || 'all';
      if (scope == 'all'){
          prButtonLockChecks['compare'] = !lockEnabled;
          prButtonLockChecks['reviewers'] = !lockEnabled;
      } else if (scope == 'compare') {
          prButtonLockChecks['compare'] = !lockEnabled;
      } else if (scope == 'reviewers'){
          prButtonLockChecks['reviewers'] = !lockEnabled;
      }
      var checksMeet = prButtonLockChecks.compare && prButtonLockChecks.reviewers;
      if (lockEnabled) {
          $('#save').attr('disabled', 'disabled');
      }
      else if (checksMeet) {
          $('#save').removeAttr('disabled');
      }

      if (msg) {
          $('#pr_open_message').html(msg);
      }
};


/**
Generate Title and Description for a PullRequest.
In case of 1 commits, the title and description is that one commit
in case of multiple commits, we iterate on them with max N number of commits,
and build description in a form
- commitN
- commitN+1
...

Title is then constructed from branch names, or other references,
replacing '-' and '_' into spaces

* @param sourceRef
* @param elements
* @param limit
* @returns {*[]}
*/
var getTitleAndDescription = function(sourceRef, elements, limit) {
  var title = '';
  var desc = '';

  $.each($(elements).get().reverse().slice(0, limit), function(idx, value) {
      var rawMessage = $(value).find('td.td-description .message').data('messageRaw');
      desc += '- ' + rawMessage.split('\n')[0].replace(/\n+$/, "") + '\n';
  });
  // only 1 commit, use commit message as title
  if (elements.length === 1) {
      title = $(elements[0]).find('td.td-description .message').data('messageRaw').split('\n')[0];
  }
  else {
      // use reference name
      title = sourceRef.replace(/-/g, ' ').replace(/_/g, ' ').capitalizeFirstLetter();
  }

  return [title, desc]
};



ReviewersController = function () {
    var self = this;
    this.$reviewRulesContainer = $('#review_rules');
    this.$rulesList = this.$reviewRulesContainer.find('.pr-reviewer-rules');
    this.forbidReviewUsers = undefined;
    this.$reviewMembers = $('#review_members');
    this.currentRequest = null;

    this.defaultForbidReviewUsers = function() {
        return [
            {'username': 'default',
             'user_id': templateContext.default_user.user_id}
        ];
    };

    this.hideReviewRules = function() {
        self.$reviewRulesContainer.hide();
    };

    this.showReviewRules = function() {
        self.$reviewRulesContainer.show();
    };

    this.addRule = function(ruleText) {
        self.showReviewRules();
        return '<div>- {0}</div>'.format(ruleText)
    };

    this.loadReviewRules = function(data) {
        // reset forbidden Users
        this.forbidReviewUsers = self.defaultForbidReviewUsers();

        // reset state of review rules
        self.$rulesList.html('');

        if (!data || data.rules === undefined || $.isEmptyObject(data.rules)) {
            // default rule, case for older repo that don't have any rules stored
            self.$rulesList.append(
                self.addRule(
                    _gettext('All reviewers must vote.'))
            );
            return self.forbidReviewUsers
        }

        if (data.rules.voting !== undefined) {
            if (data.rules.voting < 0){
                self.$rulesList.append(
                    self.addRule(
                        _gettext('All reviewers must vote.'))
                )
            } else if (data.rules.voting === 1) {
                self.$rulesList.append(
                    self.addRule(
                        _gettext('At least {0} reviewer must vote.').format(data.rules.voting))
                )

            } else {
                self.$rulesList.append(
                    self.addRule(
                        _gettext('At least {0} reviewers must vote.').format(data.rules.voting))
                )
            }
        }
        if (data.rules.use_code_authors_for_review) {
            self.$rulesList.append(
                self.addRule(
                    _gettext('Reviewers picked from source code changes.'))
            )
        }
        if (data.rules.forbid_adding_reviewers) {
            $('#add_reviewer_input').remove();
            self.$rulesList.append(
                self.addRule(
                    _gettext('Adding new reviewers is forbidden.'))
            )
        }
        if (data.rules.forbid_author_to_review) {
            self.forbidReviewUsers.push(data.rules_data.pr_author);
            self.$rulesList.append(
                self.addRule(
                    _gettext('Author is not allowed to be a reviewer.'))
            )
        }
        if (data.rules.forbid_commit_author_to_review) {

            if (data.rules_data.forbidden_users) {
                $.each(data.rules_data.forbidden_users, function(index, member_data) {
                    self.forbidReviewUsers.push(member_data)
                });

            }

            self.$rulesList.append(
                self.addRule(
                    _gettext('Commit Authors are not allowed to be a reviewer.'))
            )
        }

        return self.forbidReviewUsers
    };

    this.loadDefaultReviewers = function(sourceRepo, sourceRef, targetRepo, targetRef) {

        if (self.currentRequest) {
            // make sure we cleanup old running requests before triggering this
            // again
            self.currentRequest.abort();
        }

        $('.calculate-reviewers').show();
        // reset reviewer members
        self.$reviewMembers.empty();

        prButtonLock(true, null, 'reviewers');
        $('#user').hide(); // hide user autocomplete before load

        var url = pyroutes.url('repo_default_reviewers_data',
                {
                    'repo_name': templateContext.repo_name,
                    'source_repo': sourceRepo,
                    'source_ref': sourceRef[2],
                    'target_repo': targetRepo,
                    'target_ref': targetRef[2]
                });

        self.currentRequest = $.get(url)
            .done(function(data) {
                self.currentRequest = null;

                // review rules
                self.loadReviewRules(data);

                for (var i = 0; i < data.reviewers.length; i++) {
                  var reviewer = data.reviewers[i];
                  self.addReviewMember(
                      reviewer.user_id, reviewer.first_name,
                      reviewer.last_name, reviewer.username,
                      reviewer.gravatar_link, reviewer.reasons,
                      reviewer.mandatory);
                }
                $('.calculate-reviewers').hide();
                prButtonLock(false, null, 'reviewers');
                $('#user').show(); // show user autocomplete after load
            });
    };

    // check those, refactor
    this.removeReviewMember = function(reviewer_id, mark_delete) {
        var reviewer = $('#reviewer_{0}'.format(reviewer_id));

        if(typeof(mark_delete) === undefined){
            mark_delete = false;
        }

        if(mark_delete === true){
            if (reviewer){
                // now delete the input
                $('#reviewer_{0} input'.format(reviewer_id)).remove();
                // mark as to-delete
                var obj = $('#reviewer_{0}_name'.format(reviewer_id));
                obj.addClass('to-delete');
                obj.css({"text-decoration":"line-through", "opacity": 0.5});
            }
        }
        else{
            $('#reviewer_{0}'.format(reviewer_id)).remove();
        }
    };

    this.addReviewMember = function(id, fname, lname, nname, gravatar_link, reasons, mandatory) {
        var members = self.$reviewMembers.get(0);
        var reasons_html = '';
        var reasons_inputs = '';
        var reasons = reasons || [];
        var mandatory = mandatory || false;

        if (reasons) {
            for (var i = 0; i < reasons.length; i++) {
                reasons_html += '<div class="reviewer_reason">- {0}</div>'.format(reasons[i]);
                reasons_inputs += '<input type="hidden" name="reason" value="' + escapeHtml(reasons[i]) + '">';
            }
        }
        var tmpl = '' +
        '<li id="reviewer_{2}" class="reviewer_entry">'+
           '<input type="hidden" name="__start__" value="reviewer:mapping">'+
           '<div class="reviewer_status">'+
              '<div class="flag_status not_reviewed pull-left reviewer_member_status"></div>'+
           '</div>'+
          '<img alt="gravatar" class="gravatar" src="{0}"/>'+
          '<span class="reviewer_name user">{1}</span>'+
          reasons_html +
          '<input type="hidden" name="user_id" value="{2}">'+
          '<input type="hidden" name="__start__" value="reasons:sequence">'+
           '{3}'+
          '<input type="hidden" name="__end__" value="reasons:sequence">';

        if (mandatory) {
            tmpl += ''+
            '<div class="reviewer_member_mandatory_remove">' +
            '<i class="icon-remove-sign"></i>'+
            '</div>' +
            '<input type="hidden" name="mandatory" value="true">'+
            '<div class="reviewer_member_mandatory">' +
                '<i class="icon-lock" title="Mandatory reviewer"></i>'+
            '</div>';

        } else {
            tmpl += ''+
            '<input type="hidden" name="mandatory" value="false">'+
            '<div class="reviewer_member_remove action_button" onclick="reviewersController.removeReviewMember({2})">' +
                '<i class="icon-remove-sign"></i>'+
            '</div>';
        }
        // continue template
        tmpl += ''+
        '<input type="hidden" name="__end__" value="reviewer:mapping">'+
        '</li>' ;

        var displayname = "{0} ({1} {2})".format(
                nname, escapeHtml(fname), escapeHtml(lname));
        var element = tmpl.format(gravatar_link,displayname,id,reasons_inputs);
        // check if we don't have this ID already in
        var ids = [];
        var _els = self.$reviewMembers.find('li').toArray();
        for (el in _els){
            ids.push(_els[el].id)
        }

        var userAllowedReview = function(userId) {
            var allowed = true;
            $.each(self.forbidReviewUsers, function(index, member_data) {
                if (parseInt(userId) === member_data['user_id']) {
                    allowed = false;
                    return false // breaks the loop
                }
            });
            return allowed
        };

        var userAllowed = userAllowedReview(id);
        if (!userAllowed){
           alert(_gettext('User `{0}` not allowed to be a reviewer').format(nname));
        }
        var shouldAdd = userAllowed && ids.indexOf('reviewer_'+id) == -1;

        if(shouldAdd) {
            // only add if it's not there
            members.innerHTML += element;
        }

    };

    this.updateReviewers = function(repo_name, pull_request_id){
        var postData = '_method=put&' + $('#reviewers input').serialize();
        _updatePullRequest(repo_name, pull_request_id, postData);
    };

};


var _updatePullRequest = function(repo_name, pull_request_id, postData) {
    var url = pyroutes.url(
        'pullrequest_update',
        {"repo_name": repo_name, "pull_request_id": pull_request_id});
    if (typeof postData === 'string' ) {
        postData += '&csrf_token=' + CSRF_TOKEN;
    } else {
        postData.csrf_token = CSRF_TOKEN;
    }
    var success = function(o) {
        window.location.reload();
    };
    ajaxPOST(url, postData, success);
};

/**
 * PULL REQUEST update commits
 */
var updateCommits = function(repo_name, pull_request_id) {
    var postData = {
        '_method': 'put',
        'update_commits': true};
    _updatePullRequest(repo_name, pull_request_id, postData);
};


/**
 * PULL REQUEST edit info
 */
var editPullRequest = function(repo_name, pull_request_id, title, description) {
    var url = pyroutes.url(
        'pullrequest_update',
        {"repo_name": repo_name, "pull_request_id": pull_request_id});

    var postData = {
        '_method': 'put',
        'title': title,
        'description': description,
        'edit_pull_request': true,
        'csrf_token': CSRF_TOKEN
    };
    var success = function(o) {
        window.location.reload();
    };
    ajaxPOST(url, postData, success);
};

var initPullRequestsCodeMirror = function (textAreaId) {
    var ta = $(textAreaId).get(0);
    var initialHeight = '100px';

    // default options
    var codeMirrorOptions = {
        mode: "text",
        lineNumbers: false,
        indentUnit: 4,
        theme: 'rc-input'
    };

    var codeMirrorInstance = CodeMirror.fromTextArea(ta, codeMirrorOptions);
    // marker for manually set description
    codeMirrorInstance._userDefinedDesc = false;
    codeMirrorInstance.setSize(null, initialHeight);
    codeMirrorInstance.on("change", function(instance, changeObj) {
        var height = initialHeight;
        var lines = instance.lineCount();
        if (lines > 6 && lines < 20) {
            height = "auto"
        }
        else if (lines >= 20) {
            height = 20 * 15;
        }
        instance.setSize(null, height);

        // detect if the change was trigger by auto desc, or user input
        changeOrigin = changeObj.origin;

        if (changeOrigin === "setValue") {
            cmLog.debug('Change triggered by setValue');
        }
        else {
            cmLog.debug('user triggered change !');
            // set special marker to indicate user has created an input.
            instance._userDefinedDesc = true;
        }

    });

    return codeMirrorInstance
};

/**
 * Reviewer autocomplete
 */
var ReviewerAutoComplete = function(inputId) {
  $(inputId).autocomplete({
    serviceUrl: pyroutes.url('user_autocomplete_data'),
    minChars:2,
    maxHeight:400,
    deferRequestBy: 300, //miliseconds
    showNoSuggestionNotice: true,
    tabDisabled: true,
    autoSelectFirst: true,
    params: { user_id: templateContext.rhodecode_user.user_id, user_groups:true, user_groups_expand:true, skip_default_user:true },
    formatResult: autocompleteFormatResult,
    lookupFilter: autocompleteFilterResult,
    onSelect: function(element, data) {

        var reasons = [_gettext('added manually by "{0}"').format(templateContext.rhodecode_user.username)];
        if (data.value_type == 'user_group') {
            reasons.push(_gettext('member of "{0}"').format(data.value_display));

            $.each(data.members, function(index, member_data) {
                reviewersController.addReviewMember(
                    member_data.id, member_data.first_name, member_data.last_name,
                    member_data.username, member_data.icon_link, reasons);
            })

        } else {
          reviewersController.addReviewMember(
              data.id, data.first_name, data.last_name,
              data.username, data.icon_link, reasons);
        }

      $(inputId).val('');
    }
  });
};


VersionController = function () {
    var self = this;
    this.$verSource = $('input[name=ver_source]');
    this.$verTarget = $('input[name=ver_target]');
    this.$showVersionDiff = $('#show-version-diff');

    this.adjustRadioSelectors = function (curNode) {
        var getVal = function (item) {
            if (item == 'latest') {
                return Number.MAX_SAFE_INTEGER
            }
            else {
                return parseInt(item)
            }
        };

        var curVal = getVal($(curNode).val());
        var cleared = false;

        $.each(self.$verSource, function (index, value) {
            var elVal = getVal($(value).val());

            if (elVal > curVal) {
                if ($(value).is(':checked')) {
                    cleared = true;
                }
                $(value).attr('disabled', 'disabled');
                $(value).removeAttr('checked');
                $(value).css({'opacity': 0.1});
            }
            else {
                $(value).css({'opacity': 1});
                $(value).removeAttr('disabled');
            }
        });

        if (cleared) {
            // if we unchecked an active, set the next one to same loc.
            $(this.$verSource).filter('[value={0}]'.format(
                curVal)).attr('checked', 'checked');
        }

        self.setLockAction(false,
            $(curNode).data('verPos'),
            $(this.$verSource).filter(':checked').data('verPos')
        );
    };


    this.attachVersionListener = function () {
        self.$verTarget.change(function (e) {
            self.adjustRadioSelectors(this)
        });
        self.$verSource.change(function (e) {
            self.adjustRadioSelectors(self.$verTarget.filter(':checked'))
        });
    };

    this.init = function () {

        var curNode = self.$verTarget.filter(':checked');
        self.adjustRadioSelectors(curNode);
        self.setLockAction(true);
        self.attachVersionListener();

    };

    this.setLockAction = function (state, selectedVersion, otherVersion) {
        var $showVersionDiff = this.$showVersionDiff;

        if (state) {
            $showVersionDiff.attr('disabled', 'disabled');
            $showVersionDiff.addClass('disabled');
            $showVersionDiff.html($showVersionDiff.data('labelTextLocked'));
        }
        else {
            $showVersionDiff.removeAttr('disabled');
            $showVersionDiff.removeClass('disabled');

            if (selectedVersion == otherVersion) {
                $showVersionDiff.html($showVersionDiff.data('labelTextShow'));
            } else {
                $showVersionDiff.html($showVersionDiff.data('labelTextDiff'));
            }
        }

    };

    this.showVersionDiff = function () {
        var target = self.$verTarget.filter(':checked');
        var source = self.$verSource.filter(':checked');

        if (target.val() && source.val()) {
            var params = {
                'pull_request_id': templateContext.pull_request_data.pull_request_id,
                'repo_name': templateContext.repo_name,
                'version': target.val(),
                'from_version': source.val()
            };
            window.location = pyroutes.url('pullrequest_show', params)
        }

        return false;
    };

    this.toggleVersionView = function (elem) {

        if (this.$showVersionDiff.is(':visible')) {
            $('.version-pr').hide();
            this.$showVersionDiff.hide();
            $(elem).html($(elem).data('toggleOn'))
        } else {
            $('.version-pr').show();
            this.$showVersionDiff.show();
            $(elem).html($(elem).data('toggleOff'))
        }

        return false
    }

};