<%namespace name="dpb" file="/base/default_perms_box.mako"/>
${dpb.default_perms_box(url('edit_user_global_perms', user_id=c.user.user_id))}
