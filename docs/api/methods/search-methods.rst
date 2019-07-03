.. _search-methods-ref:

search methods
==============

search 
------

.. py:function:: search(apiuser, search_query, search_type, page_limit=<Optional:10>, page=<Optional:1>, search_sort=<Optional:'newfirst'>, repo_name=<Optional:None>, repo_group_name=<Optional:None>)

   Fetch Full Text Search results using API.

   :param apiuser: This is filled automatically from the |authtoken|.
   :type apiuser: AuthUser
   :param search_query: Search query.
   :type search_query: str
   :param search_type: Search type. The following are valid options:
       * commit
       * content
       * path
   :type search_type: str
   :param page_limit: Page item limit, from 1 to 500. Default 10 items.
   :type page_limit: Optional(int)
   :param page: Page number. Default first page.
   :type page: Optional(int)
   :param search_sort: Search sort order. Default newfirst. The following are valid options:
       * newfirst
       * oldfirst
   :type search_sort: Optional(str)
   :param repo_name: Filter by one repo. Default is all.
   :type repo_name: Optional(str)
   :param repo_group_name: Filter by one repo group. Default is all.
   :type repo_group_name: Optional(str)


