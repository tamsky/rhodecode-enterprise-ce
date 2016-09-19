ccLog = Logger.get('RhodeCodeApp');
ccLog.setLevel(Logger.OFF);

var rhodeCodeApp = Polymer({
    is: 'rhodecode-app',
    created: function () {
        ccLog.debug('rhodeCodeApp created');
        $.Topic('/notifications').subscribe(this.handleNotifications.bind(this));

        $.Topic('/plugins/__REGISTER__').subscribe(
            this.kickoffChannelstreamPlugin.bind(this)
        );

        $.Topic('/connection_controller/subscribe').subscribe(
            this.subscribeToChannelTopic.bind(this));
    },

    /** proxy to channelstream connection */
    getChannelStreamConnection: function () {
        return this.$['channelstream-connection'];
    },

    handleNotifications: function (data) {
        this.$['notifications'].handleNotification(data);
    },

    /** opens connection to ws server */
    kickoffChannelstreamPlugin: function (data) {
        ccLog.debug('kickoffChannelstreamPlugin');
        var channels = ['broadcast'];
        var addChannels = this.checkViewChannels();
        for (var i = 0; i < addChannels.length; i++) {
            channels.push(addChannels[i]);
        }
        if (window.CHANNELSTREAM_SETTINGS && CHANNELSTREAM_SETTINGS.enabled){
            var channelstreamConnection = this.$['channelstream-connection'];
            channelstreamConnection.connectUrl = CHANNELSTREAM_URLS.connect;
            channelstreamConnection.subscribeUrl = CHANNELSTREAM_URLS.subscribe;
            channelstreamConnection.websocketUrl = CHANNELSTREAM_URLS.ws + '/ws';
            channelstreamConnection.longPollUrl = CHANNELSTREAM_URLS.longpoll + '/listen';
            // some channels might already be registered by topic
            for (var i = 0; i < channels.length; i++) {
                channelstreamConnection.push('channels', channels[i]);
            }
            // append any additional channels registered in other plugins
            $.Topic('/connection_controller/subscribe').processPrepared();
            channelstreamConnection.connect();
        }
    },

    checkViewChannels: function () {
        var channels = []
        // subscribe to PR repo channel for PR's'
        if (templateContext.pull_request_data.pull_request_id) {
            var channelName = '/repo$' + templateContext.repo_name + '$/pr/' +
                String(templateContext.pull_request_data.pull_request_id);
            channels.push(channelName);
        }
        return channels;
    },

    /** subscribes users from channels in channelstream */
    subscribeToChannelTopic: function (channels) {
        var channelstreamConnection = this.$['channelstream-connection'];
        var toSubscribe = channelstreamConnection.calculateSubscribe(channels);
        ccLog.debug('subscribeToChannelTopic', toSubscribe);
        if (toSubscribe.length > 0) {
            // if we are connected then subscribe
            if (channelstreamConnection.connected) {
                channelstreamConnection.subscribe(toSubscribe);
            }
            // not connected? just push channels onto the stack
            else {
                for (var i = 0; i < toSubscribe.length; i++) {
                    channelstreamConnection.push('channels', toSubscribe[i]);
                }
            }
        }
    },

    /** publish received messages into correct topic */
    receivedMessage: function (event) {
        for (var i = 0; i < event.detail.length; i++) {
            var message = event.detail[i];
            if (message.message.topic) {
                ccLog.debug('publishing', message.message.topic);
                $.Topic(message.message.topic).publish(message);
            }
            else if (message.type === 'presence'){
                $.Topic('/connection_controller/presence').publish(message);
            }
            else {
                ccLog.warn('unhandled message', message);
            }
        }
    },

    handleConnected: function (event) {
        var channelstreamConnection = this.$['channelstream-connection'];
        channelstreamConnection.set('channelsState',
            event.detail.channels_info);
        channelstreamConnection.set('userState', event.detail.state);
        channelstreamConnection.set('channels', event.detail.channels);
        this.propagageChannelsState();
    },
    handleSubscribed: function (event) {
        var channelstreamConnection = this.$['channelstream-connection'];
        var channelInfo = event.detail.channels_info;
        var channelKeys = Object.keys(event.detail.channels_info);
        for (var i = 0; i < channelKeys.length; i++) {
            var key = channelKeys[i];
            channelstreamConnection.set(['channelsState', key], channelInfo[key]);
        }
        channelstreamConnection.set('channels', event.detail.channels);
        this.propagageChannelsState();
    },
    /** propagates channel states on topics */
    propagageChannelsState: function (event) {
        var channelstreamConnection = this.$['channelstream-connection'];
        var channel_data = channelstreamConnection.channelsState;
        var channels = channelstreamConnection.channels;
        for (var i = 0; i < channels.length; i++) {
            var key = channels[i];
            $.Topic('/connection_controller/channel_update').publish(
                {channel: key, state: channel_data[key]}
            );
        }
    }
});