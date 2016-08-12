# -*- coding: utf-8 -*-

# Copyright (C) 2012-2016  RhodeCode GmbH
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

from rhodecode.integrations.schema import IntegrationSettingsSchemaBase


class IntegrationTypeBase(object):
    """ Base class for IntegrationType plugins """

    def __init__(self, settings):
        """
        :param settings: dict of settings to be used for the integration
        """
        self.settings = settings


    def settings_schema(self):
        """
        A colander schema of settings for the integration type

        Subclasses can return their own schema but should always
        inherit from IntegrationSettingsSchemaBase
        """
        return IntegrationSettingsSchemaBase()

