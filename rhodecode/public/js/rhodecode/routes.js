
/******************************************************************************
 *                                                                            *
 *                      DO NOT CHANGE THIS FILE MANUALLY                      *
 *                                                                            *
 *                                                                            *
 *        This file is automatically generated when the app starts up with    *
 *                         generate_js_files = true                           *
 *                                                                            *
 *  To add a route here pass jsroute=True to the route definition in the app  *
 *                                                                            *
 ******************************************************************************/
function registerRCRoutes() {
    // routes registration
    pyroutes.register('new_repo', '/_admin/create_repository', []);
    pyroutes.register('edit_user', '/_admin/users/%(user_id)s/edit', ['user_id']);
    pyroutes.register('favicon', '/favicon.ico', []);
    pyroutes.register('robots', '/robots.txt', []);
    pyroutes.register('auth_home', '/_admin/auth*traverse', []);
    pyroutes.register('global_integrations_new', '/_admin/integrations/new', []);
    pyroutes.register('global_integrations_home', '/_admin/integrations', []);
    pyroutes.register('global_integrations_list', '/_admin/integrations/%(integration)s', ['integration']);
    pyroutes.register('global_integrations_create', '/_admin/integrations/%(integration)s/new', ['integration']);
    pyroutes.register('global_integrations_edit', '/_admin/integrations/%(integration)s/%(integration_id)s', ['integration', 'integration_id']);
    pyroutes.register('repo_group_integrations_home', '/%(repo_group_name)s/settings/integrations', ['repo_group_name']);
    pyroutes.register('repo_group_integrations_new', '/%(repo_group_name)s/settings/integrations/new', ['repo_group_name']);
    pyroutes.register('repo_group_integrations_list', '/%(repo_group_name)s/settings/integrations/%(integration)s', ['repo_group_name', 'integration']);
    pyroutes.register('repo_group_integrations_create', '/%(repo_group_name)s/settings/integrations/%(integration)s/new', ['repo_group_name', 'integration']);
    pyroutes.register('repo_group_integrations_edit', '/%(repo_group_name)s/settings/integrations/%(integration)s/%(integration_id)s', ['repo_group_name', 'integration', 'integration_id']);
    pyroutes.register('repo_integrations_home', '/%(repo_name)s/settings/integrations', ['repo_name']);
    pyroutes.register('repo_integrations_new', '/%(repo_name)s/settings/integrations/new', ['repo_name']);
    pyroutes.register('repo_integrations_list', '/%(repo_name)s/settings/integrations/%(integration)s', ['repo_name', 'integration']);
    pyroutes.register('repo_integrations_create', '/%(repo_name)s/settings/integrations/%(integration)s/new', ['repo_name', 'integration']);
    pyroutes.register('repo_integrations_edit', '/%(repo_name)s/settings/integrations/%(integration)s/%(integration_id)s', ['repo_name', 'integration', 'integration_id']);
    pyroutes.register('ops_ping', '/_admin/ops/ping', []);
    pyroutes.register('ops_error_test', '/_admin/ops/error', []);
    pyroutes.register('ops_redirect_test', '/_admin/ops/redirect', []);
    pyroutes.register('admin_home', '/_admin', []);
    pyroutes.register('admin_audit_logs', '/_admin/audit_logs', []);
    pyroutes.register('pull_requests_global_0', '/_admin/pull_requests/%(pull_request_id)s', ['pull_request_id']);
    pyroutes.register('pull_requests_global_1', '/_admin/pull-requests/%(pull_request_id)s', ['pull_request_id']);
    pyroutes.register('pull_requests_global', '/_admin/pull-request/%(pull_request_id)s', ['pull_request_id']);
    pyroutes.register('admin_settings_open_source', '/_admin/settings/open_source', []);
    pyroutes.register('admin_settings_vcs_svn_generate_cfg', '/_admin/settings/vcs/svn_generate_cfg', []);
    pyroutes.register('admin_settings_system', '/_admin/settings/system', []);
    pyroutes.register('admin_settings_system_update', '/_admin/settings/system/updates', []);
    pyroutes.register('admin_settings_sessions', '/_admin/settings/sessions', []);
    pyroutes.register('admin_settings_sessions_cleanup', '/_admin/settings/sessions/cleanup', []);
    pyroutes.register('admin_settings_process_management', '/_admin/settings/process_management', []);
    pyroutes.register('admin_settings_process_management_signal', '/_admin/settings/process_management/signal', []);
    pyroutes.register('admin_permissions_application', '/_admin/permissions/application', []);
    pyroutes.register('admin_permissions_application_update', '/_admin/permissions/application/update', []);
    pyroutes.register('admin_permissions_global', '/_admin/permissions/global', []);
    pyroutes.register('admin_permissions_global_update', '/_admin/permissions/global/update', []);
    pyroutes.register('admin_permissions_object', '/_admin/permissions/object', []);
    pyroutes.register('admin_permissions_object_update', '/_admin/permissions/object/update', []);
    pyroutes.register('admin_permissions_ips', '/_admin/permissions/ips', []);
    pyroutes.register('admin_permissions_overview', '/_admin/permissions/overview', []);
    pyroutes.register('admin_permissions_auth_token_access', '/_admin/permissions/auth_token_access', []);
    pyroutes.register('users', '/_admin/users', []);
    pyroutes.register('users_data', '/_admin/users_data', []);
    pyroutes.register('edit_user_auth_tokens', '/_admin/users/%(user_id)s/edit/auth_tokens', ['user_id']);
    pyroutes.register('edit_user_auth_tokens_add', '/_admin/users/%(user_id)s/edit/auth_tokens/new', ['user_id']);
    pyroutes.register('edit_user_auth_tokens_delete', '/_admin/users/%(user_id)s/edit/auth_tokens/delete', ['user_id']);
    pyroutes.register('edit_user_emails', '/_admin/users/%(user_id)s/edit/emails', ['user_id']);
    pyroutes.register('edit_user_emails_add', '/_admin/users/%(user_id)s/edit/emails/new', ['user_id']);
    pyroutes.register('edit_user_emails_delete', '/_admin/users/%(user_id)s/edit/emails/delete', ['user_id']);
    pyroutes.register('edit_user_ips', '/_admin/users/%(user_id)s/edit/ips', ['user_id']);
    pyroutes.register('edit_user_ips_add', '/_admin/users/%(user_id)s/edit/ips/new', ['user_id']);
    pyroutes.register('edit_user_ips_delete', '/_admin/users/%(user_id)s/edit/ips/delete', ['user_id']);
    pyroutes.register('edit_user_groups_management', '/_admin/users/%(user_id)s/edit/groups_management', ['user_id']);
    pyroutes.register('edit_user_groups_management_updates', '/_admin/users/%(user_id)s/edit/edit_user_groups_management/updates', ['user_id']);
    pyroutes.register('edit_user_audit_logs', '/_admin/users/%(user_id)s/edit/audit', ['user_id']);
    pyroutes.register('user_groups', '/_admin/user_groups', []);
    pyroutes.register('user_groups_data', '/_admin/user_groups_data', []);
    pyroutes.register('user_group_members_data', '/_admin/user_groups/%(user_group_id)s/members', ['user_group_id']);
    pyroutes.register('channelstream_connect', '/_admin/channelstream/connect', []);
    pyroutes.register('channelstream_subscribe', '/_admin/channelstream/subscribe', []);
    pyroutes.register('channelstream_proxy', '/_channelstream', []);
    pyroutes.register('login', '/_admin/login', []);
    pyroutes.register('logout', '/_admin/logout', []);
    pyroutes.register('register', '/_admin/register', []);
    pyroutes.register('reset_password', '/_admin/password_reset', []);
    pyroutes.register('reset_password_confirmation', '/_admin/password_reset_confirmation', []);
    pyroutes.register('home', '/', []);
    pyroutes.register('user_autocomplete_data', '/_users', []);
    pyroutes.register('user_group_autocomplete_data', '/_user_groups', []);
    pyroutes.register('repo_list_data', '/_repos', []);
    pyroutes.register('goto_switcher_data', '/_goto_data', []);
    pyroutes.register('journal', '/_admin/journal', []);
    pyroutes.register('journal_rss', '/_admin/journal/rss', []);
    pyroutes.register('journal_atom', '/_admin/journal/atom', []);
    pyroutes.register('journal_public', '/_admin/public_journal', []);
    pyroutes.register('journal_public_atom', '/_admin/public_journal/atom', []);
    pyroutes.register('journal_public_atom_old', '/_admin/public_journal_atom', []);
    pyroutes.register('journal_public_rss', '/_admin/public_journal/rss', []);
    pyroutes.register('journal_public_rss_old', '/_admin/public_journal_rss', []);
    pyroutes.register('toggle_following', '/_admin/toggle_following', []);
    pyroutes.register('repo_creating', '/%(repo_name)s/repo_creating', ['repo_name']);
    pyroutes.register('repo_creating_check', '/%(repo_name)s/repo_creating_check', ['repo_name']);
    pyroutes.register('repo_summary_explicit', '/%(repo_name)s/summary', ['repo_name']);
    pyroutes.register('repo_summary_commits', '/%(repo_name)s/summary-commits', ['repo_name']);
    pyroutes.register('repo_commit', '/%(repo_name)s/changeset/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_children', '/%(repo_name)s/changeset_children/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_parents', '/%(repo_name)s/changeset_parents/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_raw', '/%(repo_name)s/changeset-diff/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_patch', '/%(repo_name)s/changeset-patch/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_download', '/%(repo_name)s/changeset-download/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_data', '/%(repo_name)s/changeset-data/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_comment_create', '/%(repo_name)s/changeset/%(commit_id)s/comment/create', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_comment_preview', '/%(repo_name)s/changeset/%(commit_id)s/comment/preview', ['repo_name', 'commit_id']);
    pyroutes.register('repo_commit_comment_delete', '/%(repo_name)s/changeset/%(commit_id)s/comment/%(comment_id)s/delete', ['repo_name', 'commit_id', 'comment_id']);
    pyroutes.register('repo_commit_raw_deprecated', '/%(repo_name)s/raw-changeset/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_archivefile', '/%(repo_name)s/archive/%(fname)s', ['repo_name', 'fname']);
    pyroutes.register('repo_files_diff', '/%(repo_name)s/diff/%(f_path)s', ['repo_name', 'f_path']);
    pyroutes.register('repo_files_diff_2way_redirect', '/%(repo_name)s/diff-2way/%(f_path)s', ['repo_name', 'f_path']);
    pyroutes.register('repo_files', '/%(repo_name)s/files/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files:default_path', '/%(repo_name)s/files/%(commit_id)s/', ['repo_name', 'commit_id']);
    pyroutes.register('repo_files:default_commit', '/%(repo_name)s/files', ['repo_name']);
    pyroutes.register('repo_files:rendered', '/%(repo_name)s/render/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files:annotated', '/%(repo_name)s/annotate/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files:annotated_previous', '/%(repo_name)s/annotate-previous/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_nodetree_full', '/%(repo_name)s/nodetree_full/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_nodetree_full:default_path', '/%(repo_name)s/nodetree_full/%(commit_id)s/', ['repo_name', 'commit_id']);
    pyroutes.register('repo_files_nodelist', '/%(repo_name)s/nodelist/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_file_raw', '/%(repo_name)s/raw/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_file_download', '/%(repo_name)s/download/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_file_download:legacy', '/%(repo_name)s/rawfile/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_file_history', '/%(repo_name)s/history/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_file_authors', '/%(repo_name)s/authors/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files_remove_file', '/%(repo_name)s/remove_file/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files_delete_file', '/%(repo_name)s/delete_file/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files_edit_file', '/%(repo_name)s/edit_file/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files_update_file', '/%(repo_name)s/update_file/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files_add_file', '/%(repo_name)s/add_file/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_files_create_file', '/%(repo_name)s/create_file/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_refs_data', '/%(repo_name)s/refs-data', ['repo_name']);
    pyroutes.register('repo_refs_changelog_data', '/%(repo_name)s/refs-data-changelog', ['repo_name']);
    pyroutes.register('repo_stats', '/%(repo_name)s/repo_stats/%(commit_id)s', ['repo_name', 'commit_id']);
    pyroutes.register('repo_changelog', '/%(repo_name)s/changelog', ['repo_name']);
    pyroutes.register('repo_changelog_file', '/%(repo_name)s/changelog/%(commit_id)s/%(f_path)s', ['repo_name', 'commit_id', 'f_path']);
    pyroutes.register('repo_changelog_elements', '/%(repo_name)s/changelog_elements', ['repo_name']);
    pyroutes.register('repo_compare_select', '/%(repo_name)s/compare', ['repo_name']);
    pyroutes.register('repo_compare', '/%(repo_name)s/compare/%(source_ref_type)s@%(source_ref)s...%(target_ref_type)s@%(target_ref)s', ['repo_name', 'source_ref_type', 'source_ref', 'target_ref_type', 'target_ref']);
    pyroutes.register('tags_home', '/%(repo_name)s/tags', ['repo_name']);
    pyroutes.register('branches_home', '/%(repo_name)s/branches', ['repo_name']);
    pyroutes.register('bookmarks_home', '/%(repo_name)s/bookmarks', ['repo_name']);
    pyroutes.register('repo_fork_new', '/%(repo_name)s/fork', ['repo_name']);
    pyroutes.register('repo_fork_create', '/%(repo_name)s/fork/create', ['repo_name']);
    pyroutes.register('repo_forks_show_all', '/%(repo_name)s/forks', ['repo_name']);
    pyroutes.register('repo_forks_data', '/%(repo_name)s/forks/data', ['repo_name']);
    pyroutes.register('pullrequest_show', '/%(repo_name)s/pull-request/%(pull_request_id)s', ['repo_name', 'pull_request_id']);
    pyroutes.register('pullrequest_show_all', '/%(repo_name)s/pull-request', ['repo_name']);
    pyroutes.register('pullrequest_show_all_data', '/%(repo_name)s/pull-request-data', ['repo_name']);
    pyroutes.register('pullrequest_repo_refs', '/%(repo_name)s/pull-request/refs/%(target_repo_name)s', ['repo_name', 'target_repo_name']);
    pyroutes.register('pullrequest_repo_destinations', '/%(repo_name)s/pull-request/repo-destinations', ['repo_name']);
    pyroutes.register('pullrequest_new', '/%(repo_name)s/pull-request/new', ['repo_name']);
    pyroutes.register('pullrequest_create', '/%(repo_name)s/pull-request/create', ['repo_name']);
    pyroutes.register('pullrequest_update', '/%(repo_name)s/pull-request/%(pull_request_id)s/update', ['repo_name', 'pull_request_id']);
    pyroutes.register('pullrequest_merge', '/%(repo_name)s/pull-request/%(pull_request_id)s/merge', ['repo_name', 'pull_request_id']);
    pyroutes.register('pullrequest_delete', '/%(repo_name)s/pull-request/%(pull_request_id)s/delete', ['repo_name', 'pull_request_id']);
    pyroutes.register('pullrequest_comment_create', '/%(repo_name)s/pull-request/%(pull_request_id)s/comment', ['repo_name', 'pull_request_id']);
    pyroutes.register('pullrequest_comment_delete', '/%(repo_name)s/pull-request/%(pull_request_id)s/comment/%(comment_id)s/delete', ['repo_name', 'pull_request_id', 'comment_id']);
    pyroutes.register('edit_repo', '/%(repo_name)s/settings', ['repo_name']);
    pyroutes.register('edit_repo_advanced', '/%(repo_name)s/settings/advanced', ['repo_name']);
    pyroutes.register('edit_repo_advanced_delete', '/%(repo_name)s/settings/advanced/delete', ['repo_name']);
    pyroutes.register('edit_repo_advanced_locking', '/%(repo_name)s/settings/advanced/locking', ['repo_name']);
    pyroutes.register('edit_repo_advanced_journal', '/%(repo_name)s/settings/advanced/journal', ['repo_name']);
    pyroutes.register('edit_repo_advanced_fork', '/%(repo_name)s/settings/advanced/fork', ['repo_name']);
    pyroutes.register('edit_repo_caches', '/%(repo_name)s/settings/caches', ['repo_name']);
    pyroutes.register('edit_repo_perms', '/%(repo_name)s/settings/permissions', ['repo_name']);
    pyroutes.register('repo_reviewers', '/%(repo_name)s/settings/review/rules', ['repo_name']);
    pyroutes.register('repo_default_reviewers_data', '/%(repo_name)s/settings/review/default-reviewers', ['repo_name']);
    pyroutes.register('repo_maintenance', '/%(repo_name)s/settings/maintenance', ['repo_name']);
    pyroutes.register('repo_maintenance_execute', '/%(repo_name)s/settings/maintenance/execute', ['repo_name']);
    pyroutes.register('strip', '/%(repo_name)s/settings/strip', ['repo_name']);
    pyroutes.register('strip_check', '/%(repo_name)s/settings/strip_check', ['repo_name']);
    pyroutes.register('strip_execute', '/%(repo_name)s/settings/strip_execute', ['repo_name']);
    pyroutes.register('rss_feed_home', '/%(repo_name)s/feed/rss', ['repo_name']);
    pyroutes.register('atom_feed_home', '/%(repo_name)s/feed/atom', ['repo_name']);
    pyroutes.register('repo_summary', '/%(repo_name)s', ['repo_name']);
    pyroutes.register('repo_summary_slash', '/%(repo_name)s/', ['repo_name']);
    pyroutes.register('repo_group_home', '/%(repo_group_name)s', ['repo_group_name']);
    pyroutes.register('repo_group_home_slash', '/%(repo_group_name)s/', ['repo_group_name']);
    pyroutes.register('search', '/_admin/search', []);
    pyroutes.register('search_repo', '/%(repo_name)s/search', ['repo_name']);
    pyroutes.register('user_profile', '/_profiles/%(username)s', ['username']);
    pyroutes.register('my_account_profile', '/_admin/my_account/profile', []);
    pyroutes.register('my_account_edit', '/_admin/my_account/edit', []);
    pyroutes.register('my_account_update', '/_admin/my_account/update', []);
    pyroutes.register('my_account_password', '/_admin/my_account/password', []);
    pyroutes.register('my_account_password_update', '/_admin/my_account/password/update', []);
    pyroutes.register('my_account_auth_tokens', '/_admin/my_account/auth_tokens', []);
    pyroutes.register('my_account_auth_tokens_add', '/_admin/my_account/auth_tokens/new', []);
    pyroutes.register('my_account_auth_tokens_delete', '/_admin/my_account/auth_tokens/delete', []);
    pyroutes.register('my_account_emails', '/_admin/my_account/emails', []);
    pyroutes.register('my_account_emails_add', '/_admin/my_account/emails/new', []);
    pyroutes.register('my_account_emails_delete', '/_admin/my_account/emails/delete', []);
    pyroutes.register('my_account_repos', '/_admin/my_account/repos', []);
    pyroutes.register('my_account_watched', '/_admin/my_account/watched', []);
    pyroutes.register('my_account_perms', '/_admin/my_account/perms', []);
    pyroutes.register('my_account_notifications', '/_admin/my_account/notifications', []);
    pyroutes.register('my_account_notifications_toggle_visibility', '/_admin/my_account/toggle_visibility', []);
    pyroutes.register('my_account_pullrequests', '/_admin/my_account/pull_requests', []);
    pyroutes.register('my_account_pullrequests_data', '/_admin/my_account/pull_requests/data', []);
    pyroutes.register('notifications_show_all', '/_admin/notifications', []);
    pyroutes.register('notifications_mark_all_read', '/_admin/notifications/mark_all_read', []);
    pyroutes.register('notifications_show', '/_admin/notifications/%(notification_id)s', ['notification_id']);
    pyroutes.register('notifications_update', '/_admin/notifications/%(notification_id)s/update', ['notification_id']);
    pyroutes.register('notifications_delete', '/_admin/notifications/%(notification_id)s/delete', ['notification_id']);
    pyroutes.register('my_account_notifications_test_channelstream', '/_admin/my_account/test_channelstream', []);
    pyroutes.register('gists_show', '/_admin/gists', []);
    pyroutes.register('gists_new', '/_admin/gists/new', []);
    pyroutes.register('gists_create', '/_admin/gists/create', []);
    pyroutes.register('gist_show', '/_admin/gists/%(gist_id)s', ['gist_id']);
    pyroutes.register('gist_delete', '/_admin/gists/%(gist_id)s/delete', ['gist_id']);
    pyroutes.register('gist_edit', '/_admin/gists/%(gist_id)s/edit', ['gist_id']);
    pyroutes.register('gist_edit_check_revision', '/_admin/gists/%(gist_id)s/edit/check_revision', ['gist_id']);
    pyroutes.register('gist_update', '/_admin/gists/%(gist_id)s/update', ['gist_id']);
    pyroutes.register('gist_show_rev', '/_admin/gists/%(gist_id)s/%(revision)s', ['gist_id', 'revision']);
    pyroutes.register('gist_show_formatted', '/_admin/gists/%(gist_id)s/%(revision)s/%(format)s', ['gist_id', 'revision', 'format']);
    pyroutes.register('gist_show_formatted_path', '/_admin/gists/%(gist_id)s/%(revision)s/%(format)s/%(f_path)s', ['gist_id', 'revision', 'format', 'f_path']);
    pyroutes.register('debug_style_home', '/_admin/debug_style', []);
    pyroutes.register('debug_style_template', '/_admin/debug_style/t/%(t_path)s', ['t_path']);
    pyroutes.register('apiv2', '/_admin/api', []);
}
