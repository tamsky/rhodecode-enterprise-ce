## -*- coding: utf-8 -*-
<!DOCTYPE html>

<%
c.template_context['repo_name'] = getattr(c, 'repo_name', '')

if hasattr(c, 'rhodecode_db_repo'):
    c.template_context['repo_type'] = c.rhodecode_db_repo.repo_type
    c.template_context['repo_landing_commit'] = c.rhodecode_db_repo.landing_rev[1]

if getattr(c, 'rhodecode_user', None) and c.rhodecode_user.user_id:
    c.template_context['rhodecode_user']['username'] = c.rhodecode_user.username
    c.template_context['rhodecode_user']['email'] = c.rhodecode_user.email
    c.template_context['rhodecode_user']['notification_status'] = c.rhodecode_user.get_instance().user_data.get('notification_status', True)
    c.template_context['rhodecode_user']['first_name'] = c.rhodecode_user.first_name
    c.template_context['rhodecode_user']['last_name'] = c.rhodecode_user.last_name

c.template_context['visual']['default_renderer'] = h.get_visual_attr(c, 'default_renderer')
c.template_context['default_user'] = {
    'username': h.DEFAULT_USER,
    'user_id': 1
}

%>
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <script src="${h.asset('js/vendors/webcomponentsjs/webcomponents-lite.min.js', ver=c.rhodecode_version_hash)}"></script>
        <link rel="import" href="${h.asset('js/rhodecode-components.html', ver=c.rhodecode_version_hash)}">
        <title>${self.title()}</title>
        <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
        <%def name="robots()">
            <meta name="robots" content="index, nofollow"/>
        </%def>
        ${self.robots()}
        <link rel="icon" href="${h.asset('images/favicon.ico', ver=c.rhodecode_version_hash)}" sizes="16x16 32x32" type="image/png" />

        ## CSS definitions
        <%def name="css()">
            <link rel="stylesheet" type="text/css" href="${h.asset('css/style.css', ver=c.rhodecode_version_hash)}" media="screen"/>
            <!--[if lt IE 9]>
                <link rel="stylesheet" type="text/css" href="${h.asset('css/ie.css', ver=c.rhodecode_version_hash)}" media="screen"/>
            <![endif]-->
            ## EXTRA FOR CSS
            ${self.css_extra()}
        </%def>
        ## CSS EXTRA - optionally inject some extra CSS stuff needed for specific websites
        <%def name="css_extra()">
        </%def>

        ${self.css()}

        ## JAVASCRIPT
        <%def name="js()">
            <script>
                // setup Polymer options
                window.Polymer = {lazyRegister: true, dom: 'shadow'};

                // Load webcomponentsjs polyfill if browser does not support native Web Components
                (function() {
                    'use strict';
                    var onload = function() {
                        // For native Imports, manually fire WebComponentsReady so user code
                        // can use the same code path for native and polyfill'd imports.
                        if (!window.HTMLImports) {
                            document.dispatchEvent(
                                    new CustomEvent('WebComponentsReady', {bubbles: true})
                            );
                        }
                    };
                    var webComponentsSupported = (
                            'registerElement' in document
                            && 'import' in document.createElement('link')
                            && 'content' in document.createElement('template')
                    );
                    if (!webComponentsSupported) {
                    } else {
                        onload();
                    }
                })();
            </script>

            <script src="${h.asset('js/rhodecode/i18n/%s.js' % c.language, ver=c.rhodecode_version_hash)}"></script>
            <script type="text/javascript">
            // register templateContext to pass template variables to JS
            var templateContext = ${h.json.dumps(c.template_context)|n};

            var APPLICATION_URL = "${h.route_path('home').rstrip('/')}";
            var ASSET_URL = "${h.asset('')}";
            var DEFAULT_RENDERER = "${h.get_visual_attr(c, 'default_renderer')}";
            var CSRF_TOKEN = "${getattr(c, 'csrf_token', '')}";

            var APPENLIGHT = {
              enabled: ${'true' if getattr(c, 'appenlight_enabled', False) else 'false'},
              key: '${getattr(c, "appenlight_api_public_key", "")}',
              % if getattr(c, 'appenlight_server_url', None):
                  serverUrl: '${getattr(c, "appenlight_server_url", "")}',
              % endif
              requestInfo: {
              % if getattr(c, 'rhodecode_user', None):
                  ip: '${c.rhodecode_user.ip_addr}',
                  username: '${c.rhodecode_user.username}'
              % endif
              },
              tags: {
                  rhodecode_version: '${c.rhodecode_version}',
                  rhodecode_edition: '${c.rhodecode_edition}'
              }
            };

            </script>
            <%include file="/base/plugins_base.mako"/>
            <!--[if lt IE 9]>
            <script language="javascript" type="text/javascript" src="${h.asset('js/excanvas.min.js')}"></script>
            <![endif]-->
            <script language="javascript" type="text/javascript" src="${h.asset('js/rhodecode/routes.js', ver=c.rhodecode_version_hash)}"></script>
            <script> var alertMessagePayloads = ${h.flash.json_alerts(request)|n}; </script>
            ## avoide escaping the %N
            <script language="javascript" type="text/javascript" src="${h.asset('js/rhodecode-components.js', ver=c.rhodecode_version_hash)}"></script>
            <script>CodeMirror.modeURL = "${h.asset('') + 'js/mode/%N/%N.js?ver='+c.rhodecode_version_hash}";</script>


            ## JAVASCRIPT EXTRA - optionally inject some extra JS for specificed templates
            ${self.js_extra()}

            <script type="text/javascript">
            Rhodecode = (function() {
                function _Rhodecode() {
                  this.comments = new CommentsController();
                }
                return new _Rhodecode();
            })();

            $(document).ready(function(){
              show_more_event();
              timeagoActivate();
              clipboardActivate();
            })
            </script>

        </%def>

        ## JAVASCRIPT EXTRA - optionally inject some extra JS for specificed templates
        <%def name="js_extra()"></%def>
        ${self.js()}

        <%def name="head_extra()"></%def>
        ${self.head_extra()}
        ## extra stuff
        %if c.pre_code:
            ${c.pre_code|n}
        %endif
    </head>
    <body id="body">
        <noscript>
            <div class="noscript-error">
                ${_('Please enable JavaScript to use RhodeCode Enterprise')}
            </div>
        </noscript>
     ## IE hacks
      <!--[if IE 7]>
      <script>$(document.body).addClass('ie7')</script>
      <![endif]-->
      <!--[if IE 8]>
      <script>$(document.body).addClass('ie8')</script>
      <![endif]-->
      <!--[if IE 9]>
      <script>$(document.body).addClass('ie9')</script>
      <![endif]-->

      ${next.body()}
      %if c.post_code:
        ${c.post_code|n}
      %endif
    <rhodecode-app></rhodecode-app>
    </body>
</html>
