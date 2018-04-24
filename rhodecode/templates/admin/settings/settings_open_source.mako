<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">${_('Licenses of Third Party Packages')}</h3>
    </div>
    <div class="panel-body">
        <p>
            RhodeCode Enterprise uses various third party packages, many of them
            provided by the open source community.
        </p>

        % if c.opensource_licenses:
            <table class="rctable dl-settings">
                <thead>
                    <th>Product</th>
                    <th>License</th>
                </thead>
                %for product, licenses in c.opensource_licenses.items():
                <tr>
                    <td>${product}</td>
                    <td>
                        ${h.literal(', '.join([
                        '<a href="%(link)s" title="%(name)s">%(name)s</a>' % {'link':link, 'name':name}
                        if link else name
                        for name,link in licenses.items()]))}
                    </td>
                </tr>
                %endfor
            </table>
        % endif
    </div>
</div>


