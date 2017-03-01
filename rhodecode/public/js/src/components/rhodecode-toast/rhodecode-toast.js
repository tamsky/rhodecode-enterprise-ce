Polymer({
    is: 'rhodecode-toast',
    properties: {
        toasts: {
            type: Array,
            value: function(){
                return []
            }
        },
        isFixed: {
            type: Boolean,
            value: false
        },
        hasToasts: {
            type: Boolean,
            computed: '_computeHasToasts(toasts.*)'
        },
        keyEventTarget: {
            type: Object,
            value: function() {
              return document.body;
            }
        }
    },
    behaviors: [
        Polymer.IronA11yKeysBehavior
    ],
    observers: [
        '_changedToasts(toasts.splices)'
    ],

    keyBindings: {
      'esc:keyup': '_hideOnEsc'
    },

    _hideOnEsc: function (event) {
        return this.dismissNotifications();
    },

    _computeHasToasts: function(){
        return this.toasts.length > 0;
    },

    _debouncedCalc: function(){
        // calculate once in a while
        this.debounce('debouncedCalc', this.toastInWindow, 25);
    },

    conditionalClass: function(){
      return this.isFixed ? 'fixed': '';
    },

    toastInWindow: function() {
        if (!this._headerNode){
            return true
        }
        var headerHeight = this._headerNode.offsetHeight;
        var scrollPosition = window.scrollY;

        if (this.isFixed){
            this.isFixed = 1 <= scrollPosition;
        }
        else{
            this.isFixed = headerHeight <= scrollPosition;
        }
    },

    attached: function(){
        this._headerNode = document.querySelector('.header', document);
        this.listen(window,'scroll', '_debouncedCalc');
        this.listen(window,'resize', '_debouncedCalc');
        this._debouncedCalc();
    },
    _changedToasts: function(newValue, oldValue){
        $.Topic('/favicon/update').publish({count: this.toasts.length});
    },
    dismissNotifications: function(){
        $.Topic('/favicon/update').publish({count: 0});
        this.splice('toasts', 0);
    },
    handleNotification: function(data){
        if (!templateContext.rhodecode_user.notification_status && !data.message.force) {
            // do not act if notifications are disabled
            return
        }
        this.push('toasts',{
            level: data.message.level,
            message: data.message.message
        });
    },
    _gettext: _gettext
});
