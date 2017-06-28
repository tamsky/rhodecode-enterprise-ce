## DATA TABLE RE USABLE ELEMENTS FOR TAGS
## usage:
## <%namespace name="tags" file="/tags/tags_data.mako"/>
## tags.<func_name>(arg,arg2)

<%def name="compare(commit_id)">
    <input class="compare-radio-button" type="radio" name="compare_source" value="${commit_id}"/>
    <input class="compare-radio-button" type="radio" name="compare_target" value="${commit_id}"/>
</%def>

<%def name="name(name, files_url)">
     <span class="tagtag tag" title="${h.tooltip(_('Tag %s') % (name,))}">
     <a href="${files_url}"><i class="icon-tag"></i>${name}</a>
     </span>
</%def>

<%def name="date(date)">
    ${h.age_component(date)}
</%def>

<%def name="author(author)">
    <span class="tooltip" title="${h.tooltip(author)}">${h.link_to_user(author)}</span>
</%def>

<%def name="commit(message, commit_id, commit_idx)">
    <div>
        <pre><a title="${h.tooltip(message)}" href="${h.url('files_home',repo_name=c.repo_name,revision=commit_id)}">r${commit_idx}:${h.short_id(commit_id)}</a></pre>
    </div>
</%def>
