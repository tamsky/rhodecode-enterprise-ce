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

"""
Custom LRU memory manager for debugging purposes. It allows to track the keys
and the state of LRU dict.

inrae.cache is licensed under LRUDict is licensed under ZPL license
This software is Copyright (c) Zope Corporation (tm) and
Contributors. All rights reserved.
"""

import logging

from repoze.lru import LRUCache
from beaker.container import MemoryNamespaceManager, AbstractDictionaryNSManager
from rhodecode.lib.utils2 import safe_str

log = logging.getLogger(__name__)


class LRUDict(LRUCache):
    """
    Wrapper to provide partial dict access
    """

    def __setitem__(self, key, value):
        return self.put(key, value)

    def __getitem__(self, key):
        return self.get(key)

    def __contains__(self, key):
        return bool(self.get(key))

    def __delitem__(self, key):
        del self.data[key]

    def keys(self):
        return self.data.keys()


class LRUDictDebug(LRUDict):
    """
    Wrapper to provide some debug options
    """
    def _report_keys(self):
        elems_cnt = '%s/%s' % (len(self.keys()), self.size)
        # trick for pformat print it more nicely
        fmt = '\n'
        for cnt, elem in enumerate(self.keys()):
            fmt += '%s - %s\n' % (cnt+1, safe_str(elem))
        log.debug('current LRU keys (%s):%s' % (elems_cnt, fmt))

    def __getitem__(self, key):
        self._report_keys()
        return self.get(key)


class MemoryLRUNamespaceManagerBase(MemoryNamespaceManager):
    default_max_items = 10000

    def _get_factory(self, max_items):

        def Factory():
            return LRUDict(int(max_items))
        return Factory

    def __init__(self, namespace, **kwargs):
        AbstractDictionaryNSManager.__init__(self, namespace)
        if 'max_items' in kwargs:
            max_items = kwargs['max_items']
        else:
            max_items = self.default_max_items

        Factory = self._get_factory(max_items)

        self.dictionary = MemoryNamespaceManager.namespaces.get(
            self.namespace, Factory)


class MemoryLRUNamespaceManagerDebug(MemoryLRUNamespaceManagerBase):
    """
    A memory namespace manager that return with LRU dicts backend,
    special debug for testing
    """
    default_max_items = 10000

    def _get_factory(self, max_items):

        def Factory():
            return LRUDictDebug(int(max_items))
        return Factory
