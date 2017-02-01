<template is="dom-bind" id="notificationsPage">
<iron-ajax id="toggleNotifications"
           method="post"
           url="${url('my_account_notifications_toggle_visibility')}"
           content-type="application/json"
           loading="{{changeNotificationsLoading}}"
           on-response="handleNotifications"
           handle-as="json">
</iron-ajax>

<iron-ajax id="sendTestNotification"
           method="post"
           url="${url('my_account_notifications_test_channelstream')}"
           content-type="application/json"
           on-response="handleTestNotification"
           handle-as="json">
</iron-ajax>

<div class="panel panel-default">
  <div class="panel-heading">
    <h3 class="panel-title">${_('Your Live Notification Settings')}</h3>
  </div>
  <div class="panel-body">

        <p><strong>IMPORTANT:</strong> This feature requires enabled channelstream websocket server to function correctly.</p>

        <p class="hidden">Status of browser notifications permission: <strong id="browser-notification-status"></strong></p>

        <div class="form">
            <div class="fields">
                <div class="field">
                    <div class="label">
                        <label for="new_email">${_('Notifications Status')}:</label>
                    </div>
                    <div class="checkboxes">
                        <rhodecode-toggle id="live-notifications" active="[[changeNotificationsLoading]]" on-change="toggleNotifications" ${'checked' if c.rhodecode_user.get_instance().user_data.get('notification_status') else ''}></rhodecode-toggle>
                    </div>
                </div>
            </div>
        </div>
  </div>
</div>

<div class="panel panel-default">
  <div class="panel-heading">
    <h3 class="panel-title">${_('Test Notifications')}</h3>
  </div>
  <div class="panel-body">


        <div style="padding: 0px 0px 20px 0px">
            <button class="btn" id="test-notification" on-tap="testNotifications">Test flash message</button>
            <button class="btn" id="test-notification-live" on-tap="testNotificationsLive">Test live notification</button>
        </div>
            <h4 id="test-response"></h4>

  </div>



</div>

<script type="text/javascript">
    /** because im not creating a custom element for this page
     * we need to push the function onto the dom-template
     * ideally we turn this into notification-settings elements
     * then it will be cleaner
     */
    var ctrlr = $('#notificationsPage')[0];
    ctrlr.toggleNotifications = function(event){
        var ajax = $('#toggleNotifications')[0];
        ajax.headers = {"X-CSRF-Token": CSRF_TOKEN};
        ajax.body = {notification_status:event.target.active};
        ajax.generateRequest();
    };
    ctrlr.handleNotifications = function(event){
        $('#live-notifications')[0].checked = event.detail.response;
    };

    ctrlr.testNotifications = function(event){
        var levels = ['info', 'error', 'warning', 'success'];
        var level = levels[Math.floor(Math.random()*levels.length)];
        var payload = {
            message: {
                message: 'This is a test notification. ' + new Date(),
                level: level,
                force: true
            }
        };
        $.Topic('/notifications').publish(payload);
    };
    ctrlr.testNotificationsLive = function(event){
        var ajax = $('#sendTestNotification')[0];
        ajax.headers = {"X-CSRF-Token": CSRF_TOKEN};
        ajax.body = {test_msg: 'Hello !'};
        ajax.generateRequest();
    };
    ctrlr.handleTestNotification = function(event){
        var reply = event.detail.response.response;
        reply = reply || 'no reply form server';
        $('#test-response').html(reply);
    };

</script>

</template>
