# -*- coding: utf-8 -*-

# Copyright (C) 2016-2016  RhodeCode GmbH
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

import collections
import datetime
import formencode
import logging
import urlparse

from pylons import url
from pyramid.httpexceptions import HTTPFound
from pyramid.view import view_config
from recaptcha.client.captcha import submit

from rhodecode.authentication.base import authenticate, HTTP_TYPE
from rhodecode.events import UserRegistered
from rhodecode.lib import helpers as h
from rhodecode.lib.auth import (
    AuthUser, HasPermissionAnyDecorator, CSRFRequired)
from rhodecode.lib.base import get_ip_addr
from rhodecode.lib.exceptions import UserCreationError
from rhodecode.lib.utils2 import safe_str
from rhodecode.model.db import User
from rhodecode.model.forms import LoginForm, RegisterForm, PasswordResetForm
from rhodecode.model.login_session import LoginSession
from rhodecode.model.meta import Session
from rhodecode.model.settings import SettingsModel
from rhodecode.model.user import UserModel
from rhodecode.translation import _


log = logging.getLogger(__name__)

CaptchaData = collections.namedtuple(
    'CaptchaData', 'active, private_key, public_key')


def _store_user_in_session(session, username, remember=False):
    user = User.get_by_username(username, case_insensitive=True)
    auth_user = AuthUser(user.user_id)
    auth_user.set_authenticated()
    cs = auth_user.get_cookie_store()
    session['rhodecode_user'] = cs
    user.update_lastlogin()
    Session().commit()

    # If they want to be remembered, update the cookie
    if remember:
        _year = (datetime.datetime.now() +
                 datetime.timedelta(seconds=60 * 60 * 24 * 365))
        session._set_cookie_expires(_year)

    session.save()

    log.info('user %s is now authenticated and stored in '
             'session, session attrs %s', username, cs)

    # dumps session attrs back to cookie
    session._update_cookie_out()
    # we set new cookie
    headers = None
    if session.request['set_cookie']:
        # send set-cookie headers back to response to update cookie
        headers = [('Set-Cookie', session.request['cookie_out'])]
    return headers


def get_came_from(request):
    came_from = safe_str(request.GET.get('came_from', ''))
    parsed = urlparse.urlparse(came_from)
    allowed_schemes = ['http', 'https']
    if parsed.scheme and parsed.scheme not in allowed_schemes:
        log.error('Suspicious URL scheme detected %s for url %s' %
                  (parsed.scheme, parsed))
        came_from = url('home')
    elif parsed.netloc and request.host != parsed.netloc:
        log.error('Suspicious NETLOC detected %s for url %s server url '
                  'is: %s' % (parsed.netloc, parsed, request.host))
        came_from = url('home')
    elif any(bad_str in parsed.path for bad_str in ('\r', '\n')):
        log.error('Header injection detected `%s` for url %s server url ' %
                  (parsed.path, parsed))
        came_from = url('home')

    return came_from or url('home')


class LoginView(object):

    def __init__(self, context, request):
        self.request = request
        self.context = context
        self.session = request.session
        self._rhodecode_user = request.user

    def _get_template_context(self):
        return {
            'came_from': get_came_from(self.request),
            'defaults': {},
            'errors': {},
        }

    def _get_captcha_data(self):
        settings = SettingsModel().get_all_settings()
        private_key = settings.get('rhodecode_captcha_private_key')
        public_key = settings.get('rhodecode_captcha_public_key')
        active = bool(private_key)
        return CaptchaData(
            active=active, private_key=private_key, public_key=public_key)

    @view_config(
        route_name='login', request_method='GET',
        renderer='rhodecode:templates/login.html')
    def login(self):
        came_from = get_came_from(self.request)
        user = self.request.user

        # redirect if already logged in
        if user.is_authenticated and not user.is_default and user.ip_allowed:
            raise HTTPFound(came_from)

        # check if we use headers plugin, and try to login using it.
        try:
            log.debug('Running PRE-AUTH for headers based authentication')
            auth_info = authenticate(
                '', '', self.request.environ, HTTP_TYPE, skip_missing=True)
            if auth_info:
                headers = _store_user_in_session(
                    self.session, auth_info.get('username'))
                raise HTTPFound(came_from, headers=headers)
        except UserCreationError as e:
            log.error(e)
            self.session.flash(e, queue='error')

        return self._get_template_context()

    @view_config(
        route_name='login', request_method='POST',
        renderer='rhodecode:templates/login.html')
    def login_post(self):
        came_from = get_came_from(self.request)
        session = self.request.session
        login_form = LoginForm()()

        try:
            session.invalidate()
            form_result = login_form.to_python(self.request.params)
            # form checks for username/password, now we're authenticated
            headers = _store_user_in_session(
                self.session,
                username=form_result['username'],
                remember=form_result['remember'])
            log.debug('Redirecting to "%s" after login.', came_from)
            raise HTTPFound(came_from, headers=headers)
        except formencode.Invalid as errors:
            defaults = errors.value
            # remove password from filling in form again
            del defaults['password']
            render_ctx = self._get_template_context()
            render_ctx.update({
                'errors': errors.error_dict,
                'defaults': defaults,
            })
            return render_ctx

        except UserCreationError as e:
            # headers auth or other auth functions that create users on
            # the fly can throw this exception signaling that there's issue
            # with user creation, explanation should be provided in
            # Exception itself
            session.flash(e, queue='error')
            return self._get_template_context()

    @CSRFRequired()
    @view_config(route_name='logout', request_method='POST')
    def logout(self):
        LoginSession().destroy_user_session()
        return HTTPFound(url('home'))

    @HasPermissionAnyDecorator(
        'hg.admin', 'hg.register.auto_activate', 'hg.register.manual_activate')
    @view_config(
        route_name='register', request_method='GET',
        renderer='rhodecode:templates/register.html',)
    def register(self, defaults=None, errors=None):
        defaults = defaults or {}
        errors = errors or {}

        settings = SettingsModel().get_all_settings()
        register_message = settings.get('rhodecode_register_message') or ''
        captcha = self._get_captcha_data()
        auto_active = 'hg.register.auto_activate' in User.get_default_user()\
            .AuthUser.permissions['global']

        render_ctx = self._get_template_context()
        render_ctx.update({
            'defaults': defaults,
            'errors': errors,
            'auto_active': auto_active,
            'captcha_active': captcha.active,
            'captcha_public_key': captcha.public_key,
            'register_message': register_message,
        })
        return render_ctx

    @HasPermissionAnyDecorator(
        'hg.admin', 'hg.register.auto_activate', 'hg.register.manual_activate')
    @view_config(
        route_name='register', request_method='POST',
        renderer='rhodecode:templates/register.html')
    def register_post(self):
        captcha = self._get_captcha_data()
        auto_active = 'hg.register.auto_activate' in User.get_default_user()\
            .AuthUser.permissions['global']

        register_form = RegisterForm()()
        try:
            form_result = register_form.to_python(self.request.params)
            form_result['active'] = auto_active

            if captcha.active:
                response = submit(
                    self.request.params.get('recaptcha_challenge_field'),
                    self.request.params.get('recaptcha_response_field'),
                    private_key=captcha.private_key,
                    remoteip=get_ip_addr(self.request.environ))
                if captcha.active and not response.is_valid:
                    _value = form_result
                    _msg = _('bad captcha')
                    error_dict = {'recaptcha_field': _msg}
                    raise formencode.Invalid(_msg, _value, None,
                                             error_dict=error_dict)

            new_user = UserModel().create_registration(form_result)
            event = UserRegistered(user=new_user, session=self.session)
            self.request.registry.notify(event)
            self.session.flash(
                _('You have successfully registered with RhodeCode'),
                queue='success')
            Session().commit()

            redirect_ro = self.request.route_path('login')
            raise HTTPFound(redirect_ro)

        except formencode.Invalid as errors:
            del errors.value['password']
            del errors.value['password_confirmation']
            return self.register(
                defaults=errors.value, errors=errors.error_dict)

        except UserCreationError as e:
            # container auth or other auth functions that create users on
            # the fly can throw this exception signaling that there's issue
            # with user creation, explanation should be provided in
            # Exception itself
            self.session.flash(e, queue='error')
            return self.register()

    @view_config(
        route_name='reset_password', request_method=('GET', 'POST'),
        renderer='rhodecode:templates/password_reset.html')
    def password_reset(self):
        captcha = self._get_captcha_data()

        render_ctx = {
            'captcha_active': captcha.active,
            'captcha_public_key': captcha.public_key,
            'defaults': {},
            'errors': {},
        }

        if self.request.POST:
            password_reset_form = PasswordResetForm()()
            try:
                form_result = password_reset_form.to_python(
                    self.request.params)
                if h.HasPermissionAny('hg.password_reset.disabled')():
                    log.error('Failed attempt to reset password for %s.', form_result['email'] )
                    self.session.flash(
                        _('Password reset has been disabled.'),
                        queue='error')
                    return HTTPFound(self.request.route_path('reset_password'))
                if captcha.active:
                    response = submit(
                        self.request.params.get('recaptcha_challenge_field'),
                        self.request.params.get('recaptcha_response_field'),
                        private_key=captcha.private_key,
                        remoteip=get_ip_addr(self.request.environ))
                    if captcha.active and not response.is_valid:
                        _value = form_result
                        _msg = _('bad captcha')
                        error_dict = {'recaptcha_field': _msg}
                        raise formencode.Invalid(_msg, _value, None,
                                                 error_dict=error_dict)

                # Generate reset URL and send mail.
                user_email = form_result['email']
                user = User.get_by_email(user_email)
                password_reset_url = self.request.route_url(
                    'reset_password_confirmation',
                    _query={'key': user.api_key})
                UserModel().reset_password_link(
                    form_result, password_reset_url)

                # Display success message and redirect.
                self.session.flash(
                    _('Your password reset link was sent'),
                    queue='success')
                return HTTPFound(self.request.route_path('login'))

            except formencode.Invalid as errors:
                render_ctx.update({
                    'defaults': errors.value,
                    'errors': errors.error_dict,
                })

        return render_ctx

    @view_config(route_name='reset_password_confirmation',
                 request_method='GET')
    def password_reset_confirmation(self):
        if self.request.GET and self.request.GET.get('key'):
            try:
                user = User.get_by_auth_token(self.request.GET.get('key'))
                password_reset_url = self.request.route_url(
                    'reset_password_confirmation',
                    _query={'key': user.api_key})
                data = {'email': user.email}
                UserModel().reset_password(data, password_reset_url)
                self.session.flash(
                    _('Your password reset was successful, '
                      'a new password has been sent to your email'),
                    queue='success')
            except Exception as e:
                log.error(e)
                return HTTPFound(self.request.route_path('reset_password'))

        return HTTPFound(self.request.route_path('login'))
