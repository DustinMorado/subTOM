======================
subtom_rand_class_motl
======================

Randomizes a given number of classes in a motive list.

.. code-block:: Matlab

    subtom_rand_class_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'num_classes', num_classes ('2'))

Takes the motive list given by ``input_motl_fn``, and splits it into
``num_classes`` even classes using the 20th row of the motive list, and then
writes the transformed motive list out as ``output_motl_fn``. The values that go
into the 20th row start at 3 and particles that initially have negative or the
value 2 in the 20th row are ignored as described in AV3 documentation for the
behavior of class numbers.

-------
Example
-------

.. code-block:: Matlab

    subtom_rand_class_motl(...
        'input_motl_fn', 'combinedmotl/allmotl_1.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_multiref_1.em', ...
        'num_classes', '2')

--------
See Also
--------

* :doc:`subtom_compare_motls_multiref`
* :doc:`subtom_scan_angles_exact_multiref`
