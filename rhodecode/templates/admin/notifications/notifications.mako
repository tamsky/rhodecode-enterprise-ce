## -*- coding: utf-8 -*-
<%inherit file="/base/base.mako"/>

<%def name="title()">
    ${_('My Notifications')} ${c.rhodecode_user.username}
    %if c.rhodecode_name:
        &middot; ${h.branding(c.rhodecode_name)}
    %endif
</%def>

<%def name="breadcrumbs_links()">
    ${_('My Notifications')}
</%def>

<%def name="menu_bar_nav()">
    ${self.menu_items(active='admin')}
</%def>

<%def name="main()">
<div class="box">
    <!-- box / title -->
    <div class="title">
        ${self.breadcrumbs()}
        ##<ul class="links">
        ##    <li>
        ##      <span ><a href="#">${_('Compose message')}</a></span>
        ##    </li>
        ##</ul>

      <div class="notifications_buttons">
      <span id='all' class="action-link first ${'active' if c.current_filter=='all' else ''}"><a href="${h.url.current()}">${_('All')}</a></span>
      <span id='comment' class="action-link ${'active' if c.current_filter=='comment' else ''}"><a href="${h.url.current(type=c.comment_type)}">${_('Comments')}</a></span>
      <span id='pull_request' class="action-link last ${'active' if c.current_filter=='pull_request' else ''}"><a href="${h.url.current(type=c.pull_request_type)}">${_('Pull Requests')}</a></span>
      
      %if c.notifications:

      <span id='mark_all_read' class="btn btn-default">${_('Mark all as read')}</span>

      %endif
      </div>
    </div>
  <div id='notification_data' class='main-content-full'>
    <%include file='notifications_data.mako'/>
  </div>
</div>
<script type="text/javascript">
var url_action = "${h.url('notification', notification_id='__NOTIFICATION_ID__')}";
var run = function(){
  $('#notification_data').on('click','.delete-notification',function(e){
    var notification_id = e.currentTarget.id;
    deleteNotification(url_action,notification_id)
  });
  $('#notification_data').on('click','.read-notification',function(e){
    var notification_id = e.currentTarget.id;
    readNotification(url_action,notification_id)
  })
};
run();
$('#mark_all_read').on('click',function(e){
    //set notifications as read
    var url = "${h.url('notifications_mark_all_read', **request.GET.mixed())}";
    $.post(url, {'csrf_token': CSRF_TOKEN}).
      done(function(data){
          // hide notifications counter
          $('#quick_login_link > .menu_link_notifications').hide();
          $('#notification_data').html(data);
        })
        .fail(function(data, textStatus, errorThrown){
            alert("Error while saving notifications.\nError code {0} ({1}). URL: {2}".format(data.status,data.statusText,$(this)[0].url));
        });
});

var current_filter = $("${c.current_filter}");
if (current_filter.length){
    current_filter.addClass('active');
}
</script>
</%def>
