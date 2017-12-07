# -*- coding: utf-8 -*-

# Copyright (C) 2010-2017 RhodeCode GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License, version 3
# (only), as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program is dual-licensed. If you wish to learn more about the
# RhodeCode Enterprise Edition, including its added features, Support services,
# and proprietary license terms, please see https://rhodecode.com/licenses/

import os
import hashlib
import logging
from collections import namedtuple
from functools import wraps
import bleach

from rhodecode.lib import caches
from rhodecode.lib.utils2 import (
    Optional, AttributeDict, safe_str, remove_prefix, str2bool)
from rhodecode.lib.vcs.backends import base
from rhodecode.model import BaseModel
from rhodecode.model.db import (
    RepoRhodeCodeUi, RepoRhodeCodeSetting, RhodeCodeUi, RhodeCodeSetting)
from rhodecode.model.meta import Session


log = logging.getLogger(__name__)


UiSetting = namedtuple(
    'UiSetting', ['section', 'key', 'value', 'active'])

SOCIAL_PLUGINS_LIST = ['github', 'bitbucket', 'twitter', 'google']


class SettingNotFound(Exception):
    def __init__(self, setting_id):
        msg = 'Setting `{}` is not found'.format(setting_id)
        super(SettingNotFound, self).__init__(msg)


class SettingsModel(BaseModel):
    BUILTIN_HOOKS = (
        RhodeCodeUi.HOOK_REPO_SIZE, RhodeCodeUi.HOOK_PUSH,
        RhodeCodeUi.HOOK_PRE_PUSH, RhodeCodeUi.HOOK_PRETX_PUSH,
        RhodeCodeUi.HOOK_PULL, RhodeCodeUi.HOOK_PRE_PULL,
        RhodeCodeUi.HOOK_PUSH_KEY,)
    HOOKS_SECTION = 'hooks'

    def __init__(self, sa=None, repo=None):
        self.repo = repo
        self.UiDbModel = RepoRhodeCodeUi if repo else RhodeCodeUi
        self.SettingsDbModel = (
            RepoRhodeCodeSetting if repo else RhodeCodeSetting)
        super(SettingsModel, self).__init__(sa)

    def get_ui_by_key(self, key):
        q = self.UiDbModel.query()
        q = q.filter(self.UiDbModel.ui_key == key)
        q = self._filter_by_repo(RepoRhodeCodeUi, q)
        return q.scalar()

    def get_ui_by_section(self, section):
        q = self.UiDbModel.query()
        q = q.filter(self.UiDbModel.ui_section == section)
        q = self._filter_by_repo(RepoRhodeCodeUi, q)
        return q.all()

    def get_ui_by_section_and_key(self, section, key):
        q = self.UiDbModel.query()
        q = q.filter(self.UiDbModel.ui_section == section)
        q = q.filter(self.UiDbModel.ui_key == key)
        q = self._filter_by_repo(RepoRhodeCodeUi, q)
        return q.scalar()

    def get_ui(self, section=None, key=None):
        q = self.UiDbModel.query()
        q = self._filter_by_repo(RepoRhodeCodeUi, q)

        if section:
            q = q.filter(self.UiDbModel.ui_section == section)
        if key:
            q = q.filter(self.UiDbModel.ui_key == key)

        # TODO: mikhail: add caching
        result = [
            UiSetting(
                section=safe_str(r.ui_section), key=safe_str(r.ui_key),
                value=safe_str(r.ui_value), active=r.ui_active
            )
            for r in q.all()
        ]
        return result

    def get_builtin_hooks(self):
        q = self.UiDbModel.query()
        q = q.filter(self.UiDbModel.ui_key.in_(self.BUILTIN_HOOKS))
        return self._get_hooks(q)

    def get_custom_hooks(self):
        q = self.UiDbModel.query()
        q = q.filter(~self.UiDbModel.ui_key.in_(self.BUILTIN_HOOKS))
        return self._get_hooks(q)

    def create_ui_section_value(self, section, val, key=None, active=True):
        new_ui = self.UiDbModel()
        new_ui.ui_section = section
        new_ui.ui_value = val
        new_ui.ui_active = active

        if self.repo:
            repo = self._get_repo(self.repo)
            repository_id = repo.repo_id
            new_ui.repository_id = repository_id

        if not key:
            # keys are unique so they need appended info
            if self.repo:
                key = hashlib.sha1(
                    '{}{}{}'.format(section, val, repository_id)).hexdigest()
            else:
                key = hashlib.sha1('{}{}'.format(section, val)).hexdigest()

        new_ui.ui_key = key

        Session().add(new_ui)
        return new_ui

    def create_or_update_hook(self, key, value):
        ui = (
            self.get_ui_by_section_and_key(self.HOOKS_SECTION, key) or
            self.UiDbModel())
        ui.ui_section = self.HOOKS_SECTION
        ui.ui_active = True
        ui.ui_key = key
        ui.ui_value = value

        if self.repo:
            repo = self._get_repo(self.repo)
            repository_id = repo.repo_id
            ui.repository_id = repository_id

        Session().add(ui)
        return ui

    def delete_ui(self, id_):
        ui = self.UiDbModel.get(id_)
        if not ui:
            raise SettingNotFound(id_)
        Session().delete(ui)

    def get_setting_by_name(self, name):
        q = self._get_settings_query()
        q = q.filter(self.SettingsDbModel.app_settings_name == name)
        return q.scalar()

    def create_or_update_setting(
            self, name, val=Optional(''), type_=Optional('unicode')):
        """
        Creates or updates RhodeCode setting. If updates is triggered it will
        only update parameters that are explicityl set Optional instance will
        be skipped

        :param name:
        :param val:
        :param type_:
        :return:
        """

        res = self.get_setting_by_name(name)
        repo = self._get_repo(self.repo) if self.repo else None

        if not res:
            val = Optional.extract(val)
            type_ = Optional.extract(type_)

            args = (
                (repo.repo_id, name, val, type_)
                if repo else (name, val, type_))
            res = self.SettingsDbModel(*args)

        else:
            if self.repo:
                res.repository_id = repo.repo_id

            res.app_settings_name = name
            if not isinstance(type_, Optional):
                # update if set
                res.app_settings_type = type_
            if not isinstance(val, Optional):
                # update if set
                res.app_settings_value = val

        Session().add(res)
        return res

    def invalidate_settings_cache(self):
        namespace = 'rhodecode_settings'
        cache_manager = caches.get_cache_manager('sql_cache_short', namespace)
        caches.clear_cache_manager(cache_manager)

    def get_all_settings(self, cache=False):

        def _compute():
            q = self._get_settings_query()
            if not q:
                raise Exception('Could not get application settings !')

            settings = {
                'rhodecode_' + result.app_settings_name: result.app_settings_value
                for result in q
            }
            return settings

        if cache:
            log.debug('Fetching app settings using cache')
            repo = self._get_repo(self.repo) if self.repo else None
            namespace = 'rhodecode_settings'
            cache_manager = caches.get_cache_manager(
                'sql_cache_short', namespace)
            _cache_key = (
                "get_repo_{}_settings".format(repo.repo_id)
                if repo else "get_app_settings")

            return cache_manager.get(_cache_key, createfunc=_compute)

        else:
            return _compute()

    def get_auth_settings(self):
        q = self._get_settings_query()
        q = q.filter(
            self.SettingsDbModel.app_settings_name.startswith('auth_'))
        rows = q.all()
        auth_settings = {
            row.app_settings_name: row.app_settings_value for row in rows}
        return auth_settings

    def get_auth_plugins(self):
        auth_plugins = self.get_setting_by_name("auth_plugins")
        return auth_plugins.app_settings_value

    def get_default_repo_settings(self, strip_prefix=False):
        q = self._get_settings_query()
        q = q.filter(
            self.SettingsDbModel.app_settings_name.startswith('default_'))
        rows = q.all()

        result = {}
        for row in rows:
            key = row.app_settings_name
            if strip_prefix:
                key = remove_prefix(key, prefix='default_')
            result.update({key: row.app_settings_value})
        return result

    def get_repo(self):
        repo = self._get_repo(self.repo)
        if not repo:
            raise Exception(
                'Repository `{}` cannot be found inside the database'.format(
                    self.repo))
        return repo

    def _filter_by_repo(self, model, query):
        if self.repo:
            repo = self.get_repo()
            query = query.filter(model.repository_id == repo.repo_id)
        return query

    def _get_hooks(self, query):
        query = query.filter(self.UiDbModel.ui_section == self.HOOKS_SECTION)
        query = self._filter_by_repo(RepoRhodeCodeUi, query)
        return query.all()

    def _get_settings_query(self):
        q = self.SettingsDbModel.query()
        return self._filter_by_repo(RepoRhodeCodeSetting, q)

    def list_enabled_social_plugins(self, settings):
        enabled = []
        for plug in SOCIAL_PLUGINS_LIST:
            if str2bool(settings.get('rhodecode_auth_{}_enabled'.format(plug)
                                     )):
                enabled.append(plug)
        return enabled


def assert_repo_settings(func):
    @wraps(func)
    def _wrapper(self, *args, **kwargs):
        if not self.repo_settings:
            raise Exception('Repository is not specified')
        return func(self, *args, **kwargs)
    return _wrapper


class IssueTrackerSettingsModel(object):
    INHERIT_SETTINGS = 'inherit_issue_tracker_settings'
    SETTINGS_PREFIX = 'issuetracker_'

    def __init__(self, sa=None, repo=None):
        self.global_settings = SettingsModel(sa=sa)
        self.repo_settings = SettingsModel(sa=sa, repo=repo) if repo else None

    @property
    def inherit_global_settings(self):
        if not self.repo_settings:
            return True
        setting = self.repo_settings.get_setting_by_name(self.INHERIT_SETTINGS)
        return setting.app_settings_value if setting else True

    @inherit_global_settings.setter
    def inherit_global_settings(self, value):
        if self.repo_settings:
            settings = self.repo_settings.create_or_update_setting(
                self.INHERIT_SETTINGS, value, type_='bool')
            Session().add(settings)

    def _get_keyname(self, key, uid, prefix=''):
        return '{0}{1}{2}_{3}'.format(
            prefix, self.SETTINGS_PREFIX, key, uid)

    def _make_dict_for_settings(self, qs):
        prefix_match = self._get_keyname('pat', '', 'rhodecode_')

        issuetracker_entries = {}
        # create keys
        for k, v in qs.items():
            if k.startswith(prefix_match):
                uid = k[len(prefix_match):]
                issuetracker_entries[uid] = None

        # populate
        for uid in issuetracker_entries:
            issuetracker_entries[uid] = AttributeDict({
                'pat': qs.get(
                    self._get_keyname('pat', uid, 'rhodecode_')),
                'url': bleach.clean(
                    qs.get(self._get_keyname('url', uid, 'rhodecode_')) or ''),
                'pref': qs.get(
                    self._get_keyname('pref', uid, 'rhodecode_')),
                'desc': qs.get(
                    self._get_keyname('desc', uid, 'rhodecode_')),
            })
        return issuetracker_entries

    def get_global_settings(self, cache=False):
        """
        Returns list of global issue tracker settings
        """
        defaults = self.global_settings.get_all_settings(cache=cache)
        settings = self._make_dict_for_settings(defaults)
        return settings

    def get_repo_settings(self, cache=False):
        """
        Returns list of issue tracker settings per repository
        """
        if not self.repo_settings:
            raise Exception('Repository is not specified')
        all_settings = self.repo_settings.get_all_settings(cache=cache)
        settings = self._make_dict_for_settings(all_settings)
        return settings

    def get_settings(self, cache=False):
        if self.inherit_global_settings:
            return self.get_global_settings(cache=cache)
        else:
            return self.get_repo_settings(cache=cache)

    def delete_entries(self, uid):
        if self.repo_settings:
            all_patterns = self.get_repo_settings()
            settings_model = self.repo_settings
        else:
            all_patterns = self.get_global_settings()
            settings_model = self.global_settings
        entries = all_patterns.get(uid, [])

        for del_key in entries:
            setting_name = self._get_keyname(del_key, uid)
            entry = settings_model.get_setting_by_name(setting_name)
            if entry:
                Session().delete(entry)

        Session().commit()

    def create_or_update_setting(
            self, name, val=Optional(''), type_=Optional('unicode')):
        if self.repo_settings:
            setting = self.repo_settings.create_or_update_setting(
                name, val, type_)
        else:
            setting = self.global_settings.create_or_update_setting(
                name, val, type_)
        return setting


class VcsSettingsModel(object):

    INHERIT_SETTINGS = 'inherit_vcs_settings'
    GENERAL_SETTINGS = (
        'use_outdated_comments',
        'pr_merge_enabled',
        'hg_use_rebase_for_merging',
        'hg_close_branch_before_merging',
        'git_use_rebase_for_merging',
        'git_close_branch_before_merging')

    HOOKS_SETTINGS = (
        ('hooks', 'changegroup.repo_size'),
        ('hooks', 'changegroup.push_logger'),
        ('hooks', 'outgoing.pull_logger'),)
    HG_SETTINGS = (
        ('extensions', 'largefiles'),
        ('phases', 'publish'),
        ('extensions', 'evolve'),)
    GIT_SETTINGS = (
        ('vcs_git_lfs', 'enabled'),)
    GLOBAL_HG_SETTINGS = (
        ('extensions', 'largefiles'),
        ('largefiles', 'usercache'),
        ('phases', 'publish'),
        ('extensions', 'hgsubversion'),
        ('extensions', 'evolve'),)
    GLOBAL_GIT_SETTINGS = (
        ('vcs_git_lfs', 'enabled'),
        ('vcs_git_lfs', 'store_location'))
    GLOBAL_SVN_SETTINGS = (
        ('vcs_svn_proxy', 'http_requests_enabled'),
        ('vcs_svn_proxy', 'http_server_url'))

    SVN_BRANCH_SECTION = 'vcs_svn_branch'
    SVN_TAG_SECTION = 'vcs_svn_tag'
    SSL_SETTING = ('web', 'push_ssl')
    PATH_SETTING = ('paths', '/')

    def __init__(self, sa=None, repo=None):
        self.global_settings = SettingsModel(sa=sa)
        self.repo_settings = SettingsModel(sa=sa, repo=repo) if repo else None
        self._ui_settings = (
            self.HG_SETTINGS + self.GIT_SETTINGS + self.HOOKS_SETTINGS)
        self._svn_sections = (self.SVN_BRANCH_SECTION, self.SVN_TAG_SECTION)

    @property
    @assert_repo_settings
    def inherit_global_settings(self):
        setting = self.repo_settings.get_setting_by_name(self.INHERIT_SETTINGS)
        return setting.app_settings_value if setting else True

    @inherit_global_settings.setter
    @assert_repo_settings
    def inherit_global_settings(self, value):
        self.repo_settings.create_or_update_setting(
            self.INHERIT_SETTINGS, value, type_='bool')

    def get_global_svn_branch_patterns(self):
        return self.global_settings.get_ui_by_section(self.SVN_BRANCH_SECTION)

    @assert_repo_settings
    def get_repo_svn_branch_patterns(self):
        return self.repo_settings.get_ui_by_section(self.SVN_BRANCH_SECTION)

    def get_global_svn_tag_patterns(self):
        return self.global_settings.get_ui_by_section(self.SVN_TAG_SECTION)

    @assert_repo_settings
    def get_repo_svn_tag_patterns(self):
        return self.repo_settings.get_ui_by_section(self.SVN_TAG_SECTION)

    def get_global_settings(self):
        return self._collect_all_settings(global_=True)

    @assert_repo_settings
    def get_repo_settings(self):
        return self._collect_all_settings(global_=False)

    @assert_repo_settings
    def create_or_update_repo_settings(
            self, data, inherit_global_settings=False):
        from rhodecode.model.scm import ScmModel

        self.inherit_global_settings = inherit_global_settings

        repo = self.repo_settings.get_repo()
        if not inherit_global_settings:
            if repo.repo_type == 'svn':
                self.create_repo_svn_settings(data)
            else:
                self.create_or_update_repo_hook_settings(data)
                self.create_or_update_repo_pr_settings(data)

            if repo.repo_type == 'hg':
                self.create_or_update_repo_hg_settings(data)

            if repo.repo_type == 'git':
                self.create_or_update_repo_git_settings(data)

        ScmModel().mark_for_invalidation(repo.repo_name, delete=True)

    @assert_repo_settings
    def create_or_update_repo_hook_settings(self, data):
        for section, key in self.HOOKS_SETTINGS:
            data_key = self._get_form_ui_key(section, key)
            if data_key not in data:
                raise ValueError(
                    'The given data does not contain {} key'.format(data_key))

            active = data.get(data_key)
            repo_setting = self.repo_settings.get_ui_by_section_and_key(
                section, key)
            if not repo_setting:
                global_setting = self.global_settings.\
                    get_ui_by_section_and_key(section, key)
                self.repo_settings.create_ui_section_value(
                    section, global_setting.ui_value, key=key, active=active)
            else:
                repo_setting.ui_active = active
                Session().add(repo_setting)

    def update_global_hook_settings(self, data):
        for section, key in self.HOOKS_SETTINGS:
            data_key = self._get_form_ui_key(section, key)
            if data_key not in data:
                raise ValueError(
                    'The given data does not contain {} key'.format(data_key))
            active = data.get(data_key)
            repo_setting = self.global_settings.get_ui_by_section_and_key(
                section, key)
            repo_setting.ui_active = active
            Session().add(repo_setting)

    @assert_repo_settings
    def create_or_update_repo_pr_settings(self, data):
        return self._create_or_update_general_settings(
            self.repo_settings, data)

    def create_or_update_global_pr_settings(self, data):
        return self._create_or_update_general_settings(
            self.global_settings, data)

    @assert_repo_settings
    def create_repo_svn_settings(self, data):
        return self._create_svn_settings(self.repo_settings, data)

    @assert_repo_settings
    def create_or_update_repo_hg_settings(self, data):
        largefiles, phases, evolve = \
            self.HG_SETTINGS
        largefiles_key, phases_key, evolve_key = \
            self._get_settings_keys(self.HG_SETTINGS, data)

        self._create_or_update_ui(
            self.repo_settings, *largefiles, value='',
            active=data[largefiles_key])
        self._create_or_update_ui(
            self.repo_settings, *evolve, value='',
            active=data[evolve_key])
        self._create_or_update_ui(
            self.repo_settings, *phases, value=safe_str(data[phases_key]))

    def create_or_update_global_hg_settings(self, data):
        largefiles, largefiles_store, phases, hgsubversion, evolve \
            = self.GLOBAL_HG_SETTINGS
        largefiles_key, largefiles_store_key, phases_key, subversion_key, evolve_key \
            = self._get_settings_keys(self.GLOBAL_HG_SETTINGS, data)

        self._create_or_update_ui(
            self.global_settings, *largefiles, value='',
            active=data[largefiles_key])
        self._create_or_update_ui(
            self.global_settings, *largefiles_store,
            value=data[largefiles_store_key])
        self._create_or_update_ui(
            self.global_settings, *phases, value=safe_str(data[phases_key]))
        self._create_or_update_ui(
            self.global_settings, *hgsubversion, active=data[subversion_key])
        self._create_or_update_ui(
            self.global_settings, *evolve, value='',
            active=data[evolve_key])

    def create_or_update_repo_git_settings(self, data):
        # NOTE(marcink): # comma make unpack work properly
        lfs_enabled, \
            = self.GIT_SETTINGS

        lfs_enabled_key, \
            = self._get_settings_keys(self.GIT_SETTINGS, data)

        self._create_or_update_ui(
            self.repo_settings, *lfs_enabled, value=data[lfs_enabled_key],
            active=data[lfs_enabled_key])

    def create_or_update_global_git_settings(self, data):
        lfs_enabled, lfs_store_location \
            = self.GLOBAL_GIT_SETTINGS
        lfs_enabled_key, lfs_store_location_key \
            = self._get_settings_keys(self.GLOBAL_GIT_SETTINGS, data)

        self._create_or_update_ui(
            self.global_settings, *lfs_enabled, value=data[lfs_enabled_key],
            active=data[lfs_enabled_key])
        self._create_or_update_ui(
            self.global_settings, *lfs_store_location,
            value=data[lfs_store_location_key])

    def create_or_update_global_svn_settings(self, data):
        # branch/tags patterns
        self._create_svn_settings(self.global_settings, data)

        http_requests_enabled, http_server_url = self.GLOBAL_SVN_SETTINGS
        http_requests_enabled_key, http_server_url_key = self._get_settings_keys(
            self.GLOBAL_SVN_SETTINGS, data)

        self._create_or_update_ui(
            self.global_settings, *http_requests_enabled,
            value=safe_str(data[http_requests_enabled_key]))
        self._create_or_update_ui(
            self.global_settings, *http_server_url,
            value=data[http_server_url_key])

    def update_global_ssl_setting(self, value):
        self._create_or_update_ui(
            self.global_settings, *self.SSL_SETTING, value=value)

    def update_global_path_setting(self, value):
        self._create_or_update_ui(
            self.global_settings, *self.PATH_SETTING, value=value)

    @assert_repo_settings
    def delete_repo_svn_pattern(self, id_):
        ui = self.repo_settings.UiDbModel.get(id_)
        if ui and ui.repository.repo_name == self.repo_settings.repo:
            # only delete if it's the same repo as initialized settings
            self.repo_settings.delete_ui(id_)
        else:
            # raise error as if we wouldn't find this option
            self.repo_settings.delete_ui(-1)

    def delete_global_svn_pattern(self, id_):
        self.global_settings.delete_ui(id_)

    @assert_repo_settings
    def get_repo_ui_settings(self, section=None, key=None):
        global_uis = self.global_settings.get_ui(section, key)
        repo_uis = self.repo_settings.get_ui(section, key)
        filtered_repo_uis = self._filter_ui_settings(repo_uis)
        filtered_repo_uis_keys = [
            (s.section, s.key) for s in filtered_repo_uis]

        def _is_global_ui_filtered(ui):
            return (
                (ui.section, ui.key) in filtered_repo_uis_keys
                or ui.section in self._svn_sections)

        filtered_global_uis = [
            ui for ui in global_uis if not _is_global_ui_filtered(ui)]

        return filtered_global_uis + filtered_repo_uis

    def get_global_ui_settings(self, section=None, key=None):
        return self.global_settings.get_ui(section, key)

    def get_ui_settings_as_config_obj(self, section=None, key=None):
        config = base.Config()

        ui_settings = self.get_ui_settings(section=section, key=key)

        for entry in ui_settings:
            config.set(entry.section, entry.key, entry.value)

        return config

    def get_ui_settings(self, section=None, key=None):
        if not self.repo_settings or self.inherit_global_settings:
            return self.get_global_ui_settings(section, key)
        else:
            return self.get_repo_ui_settings(section, key)

    def get_svn_patterns(self, section=None):
        if not self.repo_settings:
            return self.get_global_ui_settings(section)
        else:
            return self.get_repo_ui_settings(section)

    @assert_repo_settings
    def get_repo_general_settings(self):
        global_settings = self.global_settings.get_all_settings()
        repo_settings = self.repo_settings.get_all_settings()
        filtered_repo_settings = self._filter_general_settings(repo_settings)
        global_settings.update(filtered_repo_settings)
        return global_settings

    def get_global_general_settings(self):
        return self.global_settings.get_all_settings()

    def get_general_settings(self):
        if not self.repo_settings or self.inherit_global_settings:
            return self.get_global_general_settings()
        else:
            return self.get_repo_general_settings()

    def get_repos_location(self):
        return self.global_settings.get_ui_by_key('/').ui_value

    def _filter_ui_settings(self, settings):
        filtered_settings = [
            s for s in settings if self._should_keep_setting(s)]
        return filtered_settings

    def _should_keep_setting(self, setting):
        keep = (
            (setting.section, setting.key) in self._ui_settings or
            setting.section in self._svn_sections)
        return keep

    def _filter_general_settings(self, settings):
        keys = ['rhodecode_{}'.format(key) for key in self.GENERAL_SETTINGS]
        return {
            k: settings[k]
            for k in settings if k in keys}

    def _collect_all_settings(self, global_=False):
        settings = self.global_settings if global_ else self.repo_settings
        result = {}

        for section, key in self._ui_settings:
            ui = settings.get_ui_by_section_and_key(section, key)
            result_key = self._get_form_ui_key(section, key)

            if ui:
                if section in ('hooks', 'extensions'):
                    result[result_key] = ui.ui_active
                elif result_key in ['vcs_git_lfs_enabled']:
                    result[result_key] = ui.ui_active
                else:
                    result[result_key] = ui.ui_value

        for name in self.GENERAL_SETTINGS:
            setting = settings.get_setting_by_name(name)
            if setting:
                result_key = 'rhodecode_{}'.format(name)
                result[result_key] = setting.app_settings_value

        return result

    def _get_form_ui_key(self, section, key):
        return '{section}_{key}'.format(
            section=section, key=key.replace('.', '_'))

    def _create_or_update_ui(
            self, settings, section, key, value=None, active=None):
        ui = settings.get_ui_by_section_and_key(section, key)
        if not ui:
            active = True if active is None else active
            settings.create_ui_section_value(
                section, value, key=key, active=active)
        else:
            if active is not None:
                ui.ui_active = active
            if value is not None:
                ui.ui_value = value
            Session().add(ui)

    def _create_svn_settings(self, settings, data):
        svn_settings = {
            'new_svn_branch': self.SVN_BRANCH_SECTION,
            'new_svn_tag': self.SVN_TAG_SECTION
        }
        for key in svn_settings:
            if data.get(key):
                settings.create_ui_section_value(svn_settings[key], data[key])

    def _create_or_update_general_settings(self, settings, data):
        for name in self.GENERAL_SETTINGS:
            data_key = 'rhodecode_{}'.format(name)
            if data_key not in data:
                raise ValueError(
                    'The given data does not contain {} key'.format(data_key))
            setting = settings.create_or_update_setting(
                name, data[data_key], 'bool')
            Session().add(setting)

    def _get_settings_keys(self, settings, data):
        data_keys = [self._get_form_ui_key(*s) for s in settings]
        for data_key in data_keys:
            if data_key not in data:
                raise ValueError(
                    'The given data does not contain {} key'.format(data_key))
        return data_keys

    def create_largeobjects_dirs_if_needed(self, repo_store_path):
        """
        This is subscribed to the `pyramid.events.ApplicationCreated` event. It
        does a repository scan if enabled in the settings.
        """

        from rhodecode.lib.vcs.backends.hg import largefiles_store
        from rhodecode.lib.vcs.backends.git import lfs_store

        paths = [
            largefiles_store(repo_store_path),
            lfs_store(repo_store_path)]

        for path in paths:
            if os.path.isdir(path):
                continue
            if os.path.isfile(path):
                continue
            # not a file nor dir, we try to create it
            try:
                os.makedirs(path)
            except Exception:
                log.warning('Failed to create largefiles dir:%s', path)
