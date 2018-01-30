# -*- coding: utf-8 -*-

# Copyright (C) 2010-2018 RhodeCode GmbH
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


import logging

from rhodecode.model import meta, db
from rhodecode.lib.utils2 import obfuscate_url_pw, get_encryption_key

log = logging.getLogger(__name__)


def init_model(engine, encryption_key=None):
    """
    Initializes db session, bind the engine with the metadata,
    Call this before using any of the tables or classes in the model,
    preferably once in application start

    :param engine: engine to bind to
    """
    engine_str = obfuscate_url_pw(str(engine.url))
    log.info("initializing db for %s", engine_str)
    meta.Base.metadata.bind = engine
    db.ENCRYPTION_KEY = encryption_key


def init_model_encryption(migration_models, config=None):
    from pyramid.threadlocal import get_current_registry
    config = config or get_current_registry().settings
    migration_models.ENCRYPTION_KEY = get_encryption_key(config)
    db.ENCRYPTION_KEY = get_encryption_key(config)


class BaseModel(object):
    """
    Base Model for all RhodeCode models, it adds sql alchemy session
    into instance of model

    :param sa: If passed it reuses this session instead of creating a new one
    """

    cls = None  # override in child class

    def __init__(self, sa=None):
        if sa is not None:
            self.sa = sa
        else:
            self.sa = meta.Session()

    def _get_instance(self, cls, instance, callback=None):
        """
        Gets instance of given cls using some simple lookup mechanism.

        :param cls: classes to fetch
        :param instance: int or Instance
        :param callback: callback to call if all lookups failed
        """

        if isinstance(instance, cls):
            return instance
        elif isinstance(instance, (int, long)):
            if isinstance(cls, tuple):
                # if we pass multi instances we pick first to .get()
                cls = cls[0]
            return cls.get(instance)
        else:
            if instance:
                if callback is None:
                    raise Exception(
                        'given object must be int, long or Instance of %s '
                        'got %s, no callback provided' % (cls, type(instance))
                    )
                else:
                    return callback(instance)

    def _get_user(self, user):
        """
        Helper method to get user by ID, or username fallback

        :param user: UserID, username, or User instance
        """
        return self._get_instance(
            db.User, user, callback=db.User.get_by_username)

    def _get_user_group(self, user_group):
        """
        Helper method to get user by ID, or username fallback

        :param user_group: UserGroupID, user_group_name, or UserGroup instance
        """
        return self._get_instance(
            db.UserGroup, user_group, callback=db.UserGroup.get_by_group_name)

    def _get_repo(self, repository):
        """
        Helper method to get repository by ID, or repository name

        :param repository: RepoID, repository name or Repository Instance
        """
        return self._get_instance(
            db.Repository, repository, callback=db.Repository.get_by_repo_name)

    def _get_perm(self, permission):
        """
        Helper method to get permission by ID, or permission name

        :param permission: PermissionID, permission_name or Permission instance
        """
        return self._get_instance(
            db.Permission, permission, callback=db.Permission.get_by_key)

    @classmethod
    def get_all(cls):
        """
        Returns all instances of what is defined in `cls` class variable
        """
        return cls.cls.getAll()
