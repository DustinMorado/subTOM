cd /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src
cd alignment
mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_extract_noise.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_extract_noise.sh
!mv subtom_extract_noise ../../bin/alignment/subtom_extract_noise

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_extract_subtomograms.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_extract_subtomograms.sh
!mv subtom_extract_subtomograms ../../bin/alignment/subtom_extract_subtomograms

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_parallel_sums.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_parallel_sums.sh
!mv subtom_parallel_sums ../../bin/alignment/subtom_parallel_sums

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_scan_angles_exact.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_scan_angles_exact.sh
!mv subtom_scan_angles_exact ../../bin/alignment/subtom_scan_angles_exact

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_weighted_average.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_weighted_average.sh
!mv subtom_weighted_average ../../bin/alignment/subtom_weighted_average

cd ../analysis
mcc -m -v ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_maskcorrected_fsc.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_maskcorrected_fsc.sh
!mv subtom_maskcorrected_fsc ../../bin/analysis/subtom_maskcorrected_fsc

cd ../MOTL
mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_cat_motls.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_cat_motls.sh
!mv subtom_cat_motls ../../bin/MOTL/subtom_cat_motls

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_clean_motl.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_clean_motl.sh
!mv subtom_clean_motl ../../bin/MOTL/subtom_clean_motl

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_compare_motls.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_compare_motls.sh
!mv subtom_compare_motls ../../bin/MOTL/subtom_compare_motls

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_even_odd_motl.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_even_odd_motl.sh
!mv subtom_even_odd_motl ../../bin/MOTL/subtom_even_odd_motl

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_scale_motl.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_scale_motl.sh
!mv subtom_scale_motl ../../bin/MOTL/subtom_scale_motl

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_seed_positions.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_seed_positions.sh
!mv subtom_seed_positions ../../bin/MOTL/subtom_seed_positions

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_split_motl_by_row.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_split_motl_by_row.sh
!mv subtom_split_motl_by_row ../../bin/MOTL/subtom_split_motl_by_row

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_transform_motl.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_transform_motl.sh
!mv subtom_transform_motl ../../bin/MOTL/subtom_transform_motl

cd ../utils
mcc -m -v ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_plot_filter.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_plot_filter.sh
!mv subtom_plot_filter ../../bin/utils/subtom_plot_filter

mcc -m -v ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_plot_scanned_angles.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_plot_scanned_angles.sh
!mv subtom_plot_scanned_angles ../../bin/utils/subtom_plot_scanned_angles

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_shape.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_shape.sh
!mv subtom_shape ../../bin/utils/subtom_shape

cd ../classification/multiref
mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_compare_motls.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_compare_motls.sh
!mv subtom_compare_motls ../../../bin/classification/multiref/subtom_compare_motls

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_parallel_sums.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_parallel_sums.sh
!mv subtom_parallel_sums ../../../bin/classification/multiref/subtom_parallel_sums

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_rand_class_motl.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_rand_class_motl.sh
!mv subtom_rand_class_motl ../../../bin/classification/multiref/subtom_rand_class_motl

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_scan_angles_exact.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_scan_angles_exact.sh
!mv subtom_scan_angles_exact ../../../bin/classification/multiref/subtom_scan_angles_exact

mcc -m -v ...
    -R -nojvm ...
    -R -nodisplay ...
    -R -singleCompThread ...
    -R -nosplash ...
    -N ...
    -I /net/bstore1/bstore1/briggsgrp/EMBL/software/tom ...
    -I /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src/utils ...
    subtom_weighted_average.m

!rm mccExcludedFiles.log
!rm requiredMCRProducts.txt
!rm readme.txt
!rm run_subtom_weighted_average.sh
!mv subtom_weighted_average ../../../bin/classification/multiref/subtom_weighted_average

cd /net/bstore1/bstore1/briggsgrp/dmorado/software/subTOM/src