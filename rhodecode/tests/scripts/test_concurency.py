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

"""
Test suite for making push/pull operations
"""

import os
import sys
import shutil
import logging
from os.path import join as jn
from os.path import dirname as dn

from tempfile import _RandomNameSequence
from subprocess32 import Popen, PIPE
from paste.deploy import appconfig

from rhodecode.lib.utils import add_cache
from rhodecode.lib.utils2 import engine_from_config
from rhodecode.lib.auth import get_crypt_password
from rhodecode.model import init_model
from rhodecode.model import meta
from rhodecode.model.db import User, Repository

from rhodecode.tests import TESTS_TMP_PATH, HG_REPO
from rhodecode.config.environment import load_environment

rel_path = dn(dn(dn(dn(os.path.abspath(__file__)))))
conf = appconfig('config:rc.ini', relative_to=rel_path)
load_environment(conf.global_conf, conf.local_conf)

add_cache(conf)

USER = 'test_admin'
PASS = 'test12'
HOST = 'rc.local'
METHOD = 'pull'
DEBUG = True
log = logging.getLogger(__name__)


class Command(object):

    def __init__(self, cwd):
        self.cwd = cwd

    def execute(self, cmd, *args):
        """Runs command on the system with given ``args``.
        """

        command = cmd + ' ' + ' '.join(args)
        log.debug('Executing %s' % command)
        if DEBUG:
            print command
        p = Popen(command, shell=True, stdout=PIPE, stderr=PIPE, cwd=self.cwd)
        stdout, stderr = p.communicate()
        if DEBUG:
            print stdout, stderr
        return stdout, stderr


def get_session():
    engine = engine_from_config(conf, 'sqlalchemy.db1.')
    init_model(engine)
    sa = meta.Session
    return sa


def create_test_user(force=True):
    print 'creating test user'
    sa = get_session()

    user = sa.query(User).filter(User.username == USER).scalar()

    if force and user is not None:
        print 'removing current user'
        for repo in sa.query(Repository).filter(Repository.user == user).all():
            sa.delete(repo)
        sa.delete(user)
        sa.commit()

    if user is None or force:
        print 'creating new one'
        new_usr = User()
        new_usr.username = USER
        new_usr.password = get_crypt_password(PASS)
        new_usr.email = 'mail@mail.com'
        new_usr.name = 'test'
        new_usr.lastname = 'lasttestname'
        new_usr.active = True
        new_usr.admin = True
        sa.add(new_usr)
        sa.commit()

    print 'done'


def create_test_repo(force=True):
    print 'creating test repo'
    from rhodecode.model.repo import RepoModel
    sa = get_session()

    user = sa.query(User).filter(User.username == USER).scalar()
    if user is None:
        raise Exception('user not found')

    repo = sa.query(Repository).filter(Repository.repo_name == HG_REPO).scalar()

    if repo is None:
        print 'repo not found creating'

        form_data = {'repo_name': HG_REPO,
                     'repo_type': 'hg',
                     'private':False,
                     'clone_uri': '' }
        rm = RepoModel(sa)
        rm.base_path = '/home/hg'
        rm.create(form_data, user)

    print 'done'


def get_anonymous_access():
    sa = get_session()
    return sa.query(User).filter(User.username == 'default').one().active


#==============================================================================
# TESTS
#==============================================================================
def test_clone_with_credentials(repo=HG_REPO, method=METHOD,
                                seq=None, backend='hg', check_output=True):
    cwd = path = jn(TESTS_TMP_PATH, repo)

    if seq is None:
        seq = _RandomNameSequence().next()

    try:
        shutil.rmtree(path, ignore_errors=True)
        os.makedirs(path)
    except OSError:
        raise

    clone_url = 'http://%(user)s:%(pass)s@%(host)s/%(cloned_repo)s' % \
                  {'user': USER,
                   'pass': PASS,
                   'host': HOST,
                   'cloned_repo': repo, }

    dest = path + seq
    if method == 'pull':
        stdout, stderr = Command(cwd).execute(backend, method, '--cwd', dest, clone_url)
    else:
        stdout, stderr = Command(cwd).execute(backend, method, clone_url, dest)
        if check_output:
            if backend == 'hg':
                assert """adding file changes""" in stdout, 'no messages about cloning'
                assert """abort""" not in stderr, 'got error from clone'
            elif backend == 'git':
                assert """Cloning into""" in stdout, 'no messages about cloning'

if __name__ == '__main__':
    try:
        create_test_user(force=False)
        seq = None
        import time

        try:
            METHOD = sys.argv[3]
        except Exception:
            pass

        try:
            backend = sys.argv[4]
        except Exception:
            backend = 'hg'

        if METHOD == 'pull':
            seq = _RandomNameSequence().next()
            test_clone_with_credentials(repo=sys.argv[1], method='clone',
                                        seq=seq, backend=backend)
        s = time.time()
        for i in range(1, int(sys.argv[2]) + 1):
            print 'take', i
            test_clone_with_credentials(repo=sys.argv[1], method=METHOD,
                                        seq=seq, backend=backend)
        print 'time taken %.3f' % (time.time() - s)
    except Exception as e:
        sys.exit('stop on %s' % e)
