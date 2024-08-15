=====================
widevariant-apptainer
=====================


    Build containers to support WideVariant runs on HPCs


Builds Apptainer containers to support WideVariant runs on clusters.
Most functionality is contained in :code:`widevariant.sif`.
:code:`srst2.sif` supports legacy dependencies of SRST2.

Installation
============

.. code-block:: bash

    git clone https://github.com/t-silvers/widevariant-apptainer.git

Usage
=====

Build
-----

Build containers usings

.. code-block:: bash

    cd widevariant-apptainer
    make build img_dir=/path/to/containers/dest

which should (after >30 mins) generate

.. code-block:: bash

    ls /path/to/containers/dest
    # srst2.sif  widevariant.sif

Test
----

.. code-block:: bash

    cd widevariant-apptainer
    make -j 8 test img_dir=/path/to/containers/dest