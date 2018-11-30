.. _hg-big-files:

|hg| Large Files Extension
==========================

Large files, such as image or zip files can cause a lot of bandwidth overhead
during clone, push, and pull operations. To remove this inefficiency, |hg|
has a large files extension which tracks their revisions by checksums. This
means that the large files are only downloaded when they are needed as part
of the current revision. This saves both disk space and bandwidth.


Enabling HG Largefiles
++++++++++++++++++++++

Mercurial Largefiles extension is disabled by default within RhodeCode Server.

To enable Mercurial Largefiles Globally:

    - Go to :menuselection:`Admin --> Settings --> VCS`

    - Scroll down into `Mercurial settings`

    - Tick `Enable largefiles extension`

    - Save your settings.

Those settings apply globally to each repository that inherits from the defaults
You can leave `largefiles extension` disabled globally, and only enable it per
repository that would use the largefiles.


.. note::

    You might want to adjust the global storage location at that point, however
    we recommend leaving the default one created.


Installing and using the |hg| Largefiles
++++++++++++++++++++++++++++++++++++++++

To find out more, see the |hg| `Large Files Extensions Documentation`_.

To configure the large files extension, you need to set up your
:file:`~/.hgrc` file.

1. Open your :file:`~/.hgrc` file.
2. Add ``largefiles =`` to the ``[extensions]`` section.
3. Configure the ``[largefiles]`` section with the patterns and file size you
   wish |hg| to handle as large. The ``minsize`` option is specified in
   megabytes.
4. Save your changes.

.. code-block:: ini

    [extensions]
    hgext.churn =
    largefiles =
    rebase =
    record =
    histedit =

    [largefiles]
    patterns = re:.*\.(png|bmp|jpg|zip|tar|tar.gz|rar)$
    minsize = 10

For a complete :file:`~/.hgrc` file example, see :ref:`config-hgrc`.

.. _Large Files Extensions Documentation: http://mercurial.selenic.com/wiki/LargefilesExtension
