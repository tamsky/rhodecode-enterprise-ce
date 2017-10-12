# Copyright (C) 2016-2017 RhodeCode GmbH
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

from pyramid.i18n import TranslationStringFactory, TranslationString

# Create a translation string factory for the 'rhodecode' domain.
_ = TranslationStringFactory('rhodecode')


class LazyString(object):
    def __init__(self, *args, **kw):
        self.args = args
        self.kw = kw

    def eval(self):
        return _(*self.args, **self.kw)

    def __unicode__(self):
        return unicode(self.eval())

    def __str__(self):
        return self.eval()

    def __mod__(self, other):
        return self.eval() % other

    def format(self, *args):
        return self.eval().format(*args)


def lazy_ugettext(*args, **kw):
    """ Lazily evaluated version of _() """
    return LazyString(*args, **kw)


def _pluralize(msgid1, msgid2, n, mapping=None):
    if n == 1:
        return _(msgid1, mapping=mapping)
    else:
        return _(msgid2, mapping=mapping)
