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

import copy
import mock
import pytest

from rhodecode.lib import helpers
from rhodecode.lib.utils2 import AttributeDict
from rhodecode.model.settings import IssueTrackerSettingsModel
from rhodecode.tests import no_newline_id_generator


@pytest.mark.parametrize('url, expected_url', [
    ('http://rc.rc/test', '<a href="http://rc.rc/test">http://rc.rc/test</a>'),
    ('http://rc.rc/@foo', '<a href="http://rc.rc/@foo">http://rc.rc/@foo</a>'),
    ('http://rc.rc/!foo', '<a href="http://rc.rc/!foo">http://rc.rc/!foo</a>'),
    ('http://rc.rc/&foo', '<a href="http://rc.rc/&foo">http://rc.rc/&foo</a>'),
    ('http://rc.rc/#foo', '<a href="http://rc.rc/#foo">http://rc.rc/#foo</a>'),
])
def test_urlify_text(url, expected_url):
    assert helpers.urlify_text(url) == expected_url


@pytest.mark.parametrize('repo_name, commit_id, path, expected_result', [
    ('rX<X', 'cX<X', 'pX<X/aX<X/bX<X',
     '<a class="pjax-link" href="/rX%3CX/files/cX%3CX/">rX&lt;X</a>/'
     '<a class="pjax-link" href="/rX%3CX/files/cX%3CX/pX%3CX">pX&lt;X</a>/'
     '<a class="pjax-link" href="/rX%3CX/files/cX%3CX/pX%3CX/aX%3CX">aX&lt;X'
     '</a>/bX&lt;X'),
    # Path with only one segment
    ('rX<X', 'cX<X', 'pX<X',
     '<a class="pjax-link" href="/rX%3CX/files/cX%3CX/">rX&lt;X</a>/pX&lt;X'),
    # Empty path
    ('rX<X', 'cX<X', '', 'rX&lt;X'),
    ('rX"X', 'cX"X', 'pX"X/aX"X/bX"X',
     '<a class="pjax-link" href="/rX%22X/files/cX%22X/">rX&#34;X</a>/'
     '<a class="pjax-link" href="/rX%22X/files/cX%22X/pX%22X">pX&#34;X</a>/'
     '<a class="pjax-link" href="/rX%22X/files/cX%22X/pX%22X/aX%22X">aX&#34;X'
     '</a>/bX&#34;X'),
], ids=['simple', 'one_segment', 'empty_path', 'simple_quote'])
def test_files_breadcrumbs_xss(
        repo_name, commit_id, path, app, expected_result):
    result = helpers.files_breadcrumbs(repo_name, commit_id, path)
    # Expect it to encode all path fragments properly. This is important
    # because it returns an instance of `literal`.
    assert result == expected_result


def test_format_binary():
    assert helpers.format_byte_size_binary(298489462784) == '278.0 GiB'


@pytest.mark.parametrize('text_string, pattern, expected', [
    ('No issue here', '(?:#)(?P<issue_id>\d+)', []),
    ('Fix #42', '(?:#)(?P<issue_id>\d+)',
     [{'url': 'http://r.io/{repo}/i/42', 'id': '42'}]),
    ('Fix #42, #53', '(?:#)(?P<issue_id>\d+)', [
     {'url': 'http://r.io/{repo}/i/42', 'id': '42'},
     {'url': 'http://r.io/{repo}/i/53', 'id': '53'}]),
    ('Fix #42', '(?:#)?<issue_id>\d+)', []),  # Broken regex
])
def test_extract_issues(backend, text_string, pattern, expected):
    repo = backend.create_repo()
    config = {
        '123': {
            'uid': '123',
            'pat': pattern,
            'url': 'http://r.io/${repo}/i/${issue_id}',
            'pref': '#',
        }
    }

    def get_settings_mock(self, cache=True):
        return config

    with mock.patch.object(IssueTrackerSettingsModel,
                           'get_settings', get_settings_mock):
        text, issues = helpers.process_patterns(text_string, repo.repo_name)

    expected = copy.deepcopy(expected)
    for item in expected:
        item['url'] = item['url'].format(repo=repo.repo_name)

    assert issues == expected


@pytest.mark.parametrize('text_string, pattern, link_format, expected_text', [
    ('Fix #42', '(?:#)(?P<issue_id>\d+)', 'html',
     'Fix <a class="issue-tracker-link" href="http://r.io/{repo}/i/42">#42</a>'),

    ('Fix #42', '(?:#)(?P<issue_id>\d+)', 'markdown',
     'Fix [#42](http://r.io/{repo}/i/42)'),

    ('Fix #42', '(?:#)(?P<issue_id>\d+)', 'rst',
     'Fix `#42 <http://r.io/{repo}/i/42>`_'),

    ('Fix #42', '(?:#)?<issue_id>\d+)', 'html',
     'Fix #42'),  # Broken regex
])
def test_process_patterns_repo(backend, text_string, pattern, expected_text, link_format):
    repo = backend.create_repo()

    def get_settings_mock(self, cache=True):
        return {
            '123': {
                'uid': '123',
                'pat': pattern,
                'url': 'http://r.io/${repo}/i/${issue_id}',
                'pref': '#',
            }
        }

    with mock.patch.object(IssueTrackerSettingsModel,
                           'get_settings', get_settings_mock):
        processed_text, issues = helpers.process_patterns(
            text_string, repo.repo_name, link_format)

    assert processed_text == expected_text.format(repo=repo.repo_name)


@pytest.mark.parametrize('text_string, pattern, expected_text', [
    ('Fix #42', '(?:#)(?P<issue_id>\d+)',
     'Fix <a class="issue-tracker-link" href="http://r.io/i/42">#42</a>'),
    ('Fix #42', '(?:#)?<issue_id>\d+)',
     'Fix #42'),  # Broken regex
])
def test_process_patterns_no_repo(text_string, pattern, expected_text):

    def get_settings_mock(self, cache=True):
        return {
            '123': {
                'uid': '123',
                'pat': pattern,
                'url': 'http://r.io/i/${issue_id}',
                'pref': '#',
            }
        }

    with mock.patch.object(IssueTrackerSettingsModel,
                           'get_global_settings', get_settings_mock):
        processed_text, issues = helpers.process_patterns(
            text_string, '')

    assert processed_text == expected_text


def test_process_patterns_non_existent_repo_name(backend):
    text_string = 'Fix #42'
    pattern = '(?:#)(?P<issue_id>\d+)'
    expected_text = ('Fix <a class="issue-tracker-link" '
                     'href="http://r.io/do-not-exist/i/42">#42</a>')

    def get_settings_mock(self, cache=True):
        return {
            '123': {
                'uid': '123',
                'pat': pattern,
                'url': 'http://r.io/${repo}/i/${issue_id}',
                'pref': '#',
            }
        }

    with mock.patch.object(IssueTrackerSettingsModel,
                           'get_global_settings', get_settings_mock):
        processed_text, issues = helpers.process_patterns(
            text_string, 'do-not-exist')

    assert processed_text == expected_text


def test_get_visual_attr(baseapp):
    from rhodecode.apps._base import TemplateArgs
    c = TemplateArgs()
    assert None is helpers.get_visual_attr(c, 'fakse')

    # emulate the c.visual behaviour
    c.visual = AttributeDict({})
    assert None is helpers.get_visual_attr(c, 'some_var')

    c.visual.some_var = 'foobar'
    assert 'foobar' == helpers.get_visual_attr(c, 'some_var')


@pytest.mark.parametrize('test_text, inclusive, expected_text', [
    ('just a string', False, 'just a string'),
    ('just a string\n', False, 'just a string'),
    ('just a string\n next line', False, 'just a string...'),
    ('just a string\n next line', True, 'just a string\n...'),
], ids=no_newline_id_generator)
def test_chop_at(test_text, inclusive, expected_text):
    assert helpers.chop_at_smart(
        test_text, '\n', inclusive, '...') == expected_text
