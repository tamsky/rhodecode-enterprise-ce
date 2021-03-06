<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('User')}: ${c.user.username}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${_('User')}: ${c.user.username}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='my_account')}
</%def>

<%def name="main()">
<div class="box">
  <div class="title">
      ${self.breadcrumbs()}
  </div>

  <div class="sidebar-col-wrapper scw-small">
    ##main
    <div class="sidebar">
        <ul class="nav nav-pills nav-stacked">
          <li class="${'active' if c.active=='user_profile' else ''}">
              <a href="${h.route_path('user_profile', username=c.user.username)}">${_('Profile')}</a></li>
          ## These placeholders are here only for styling purposes. For every new item added to the list, you should remove one placeholder
          <li class="placeholder"><a href="#" style="visibility: hidden;">placeholder</a></li>
          <li class="placeholder"><a href="#" style="visibility: hidden;">placeholder</a></li>
          <li class="placeholder"><a href="#" style="visibility: hidden;">placeholder</a></li>
          <li class="placeholder"><a href="#" style="visibility: hidden;">placeholder</a></li>
          <li class="placeholder"><a href="#" style="visibility: hidden;">placeholder</a></li>
          <li class="placeholder"><a href="#" style="visibility: hidden;">placeholder</a></li>
        </ul>
    </div>

    <div class="main-content-full-width">
        <%include file="/users/${c.active}.mako"/>
    </div>
  </div>
</div>

</%def>
