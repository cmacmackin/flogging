#!/bin/bash

set -e
set -v

FoBiS.py build -mode gnu-static -dlib ${LOCAL_ROOT}/lib -i ${LOCAL_ROOT}/include -coverage
for f in tests/*.pf
do
    ${PFUNIT}/bin/pFUnitParser.py $f ${f%.*}.F90
done
if [ -e tests/driver.F90 ]; then rm tests/driver.F90; fi
ln -s ${PFUNIT}/include/driver.F90 tests/
mkdir -p tests_build $(FoBiS.py rule -mode tests -get build_dir)
if FoBiS.py build -mode tests -coverage ; then
    $(FoBiS.py rule -mode tests -get_output_name)
    gcov $(FoBiS.py rule -mode gnu-static -get build_dir)/$(FoBiS.py rule -mode gnu-static -get obj_dir)/*.gcno -pb
else
    echo "Failed to build tests."
    exit 1
fi
