<%namespace name="widgets" file="/widgets.mako"/>

<%widgets:panel title="${_('Change Your Account Password')}">

% if c.extern_type != 'rhodecode':
    <p>${_('Your user account details are managed by an external source. Details cannot be managed here.')}
       <br/>${_('Source type')}: <strong>${c.extern_type}</strong>
    </p>
% else:
    ${c.form.render() | n}
% endif

</%widgets:panel>
