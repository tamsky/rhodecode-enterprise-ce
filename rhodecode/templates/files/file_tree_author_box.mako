<%namespace name="base" file="/base/base.mako"/>

<div class="summary-detail-header">
  <h4 class="item">
    ${_('Commit Author')}
  </h4>
</div>
<div class="sidebar-right-content">
    ${base.gravatar_with_user(c.commit.author)}
    <div class="user-inline-data">- ${h.age_component(c.commit.date)}</div>
</div>

