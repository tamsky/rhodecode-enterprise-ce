<script>
    var CHANNELSTREAM_URLS = ${config['url_gen'](request)|n};
    %if request.registry.rhodecode_plugins['channelstream']['enabled'] and c.rhodecode_user.username != h.DEFAULT_USER:
    var CHANNELSTREAM_SETTINGS = {
        'enabled': true,
        'ws_location': '${request.registry.settings.get('channelstream.ws_url')}',
            'webapp_location': '${h.url('/', qualified=True)[:-1]}'
    };
    %else:
    var CHANNELSTREAM_SETTINGS = {
        'enabled':false,
        'ws_location': '',
        'webapp_location': ''};
    %endif

</script>