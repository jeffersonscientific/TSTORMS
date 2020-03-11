#! /bin/bash

#SBATCH -n 1
#SBATCH -o tstorms_compile_out.out
#SBATCH -e tstorms_compile_out.err
#
# set up modules, compile variables, etc.
module purge
module unuse /usr/local/modulefiles
#
#module load intel/19.1.0.166
module load intel/19
#
TARGET_PATH_ROOT=/share/cees/software
#
# Choose your MPI:
# (this appears to compile correctly -- on Mazama, for OpenMPI-3, MPICH/3, and impi/2019)
module load impi/
COMP_MPI=intel19_impi19
#
#module load openmpi3
#module load openmpi_3
#COMP_MPI=intel19_openmpi3
#
#module load mpich/3.3.1
#COMP_MPI=intel19_mpich3
#
###################
# share modules:
#module load hdf4
module load nco
#
module load netcdf
module load netcdf-fortran
#
module load autotools
#module load cmake
#
echo "module list: "
module list
#
#
# Should we set these in the module file?
CC=icc
FC=ifort
CXX=icpc
#
# older compile scripts might need more help with this:
F77=$FC
F90=$FC
#
# MPI compilers:
MPICC=mpiicc
MPIFC=mpiifort
MPICXX=mpiicpc
#
ROOT_DIR=`pwd`
echo "root dir: ${ROOT_DIR}"
#
# Set this value; if you are ok with the subsequent directory structure, you can leave the rest alone. eventually
#  we'll want smarter version management.
#
###############################################
# Which parts do we do?
# TODO: separate these installations? Manage HDF4, NCO separately? Maybe for now, we create the NCO, HDF4 SW and reference
#  this script; parse it out later, if the time comes that we need to do that?
DO_HDF4=0
DO_NCO=0
DO_TSTORMS=1
###############################################
#
#
TSTORMS=tropical_storms_pub
TSTORMS_TAR=TSTORMS.tar.gz
TSTORMS_SRC=${ROOT_DIR}/${TSTORMS}
#

TSTORMS_DIR=${TARGET_PATH_ROOT}/tstorms/${COMP_MPI}/1.0.0
#
export LD_LIBRARY_PATH=${NCO_DIR}/lib:${LD_LIBRARY_PATH}
export LIBRARY_PATH=${NCO_DIR}/lib:${LIBRARY_PATH}
export PATH=${NCO_DIR}/bin:${PATH}
#
C_FLAGS='-fpic '
#CPP_FLAGS="-I${HDF5_INC} "
CPP_FLAGS="`nc-config --cflags` -I${MPI_DIR}/include"
#echo "** ** ** CPP_FLAGS: ${CPP_FLAGS}"
#
# FUNFACT: Turns out that `nf-config --fflags` is (sometimes?) disabled for "cmake", which amounts
#   to for a bunch of other stuff too, like just running it in a script, like this:
#  this returns a message "not enabled for cmake" or something, which obviously makes
#  everything break. For what reason, I do not know...
#FFLAGS="-fpic `nf-config --fflags` "
FFLAGS="-fpic -I${NETCDF_FORTRAN_INC} "
echo "** * * ** FFLAGS: ${FFLAGS}"

#
# TODO: LD_FLAGS should be set for each compile group.g
#LD_FLAGS="`nc-config --libs` -L${NCF_DIR}/lib -L${ZDIR}/lib -L${CURLDIR}/lib -L${H5DIR}/lib "
LD_FLAGS="`nc-config --libs`  -L${HDF5_LIB} -L${MPI_DIR}/lib"
echo "*** LD_FLAGS: ${LD_FLAGS}"
#
#LIBS="-lnetcdf `nf-config --flibs` "
#
#
# Also ANTLR? this will (apparently?) only compile with gnu compiler... dunno, but it also only appears to have c/c++ components, so
#  that is probably ok. also, might be able to just do a pip install, for the Python hooks, and maybe get the c++ bits (or at lest
#  referenced/included/linked components) along the way.
#https://www.antlr.org/download/antlr4-cpp-runtime-4.8-source.zip
#
#

#
###########################
# TSTORMS:
###########################
echo "Doing TSTORMS bits... "
if [ -f ${TSTORMS_TAR} ]; then
    echo "TSTORMS file exists: ${TSTORMS_TAR}"
else
    echo "downloading TSTORMS:"
    wget ftp://ftp.gfdl.noaa.gov/perm/GFDL_pubrelease/TSTORMS/${TSTORMS_TAR}
fi
#
if [ -d "${TSTORMS_SRC}" ]; then
    echo "TSTORMS_SRC exists: ${TSTORMS_SRC}"
else
    # this would be the place to nest the if-file bit...
    tar xfvz ${TSTORMS_TAR}
fi
#
if [ -d "${TSTORMS_DIR}" ]; then
    echo "TSTORMS_DIR exists: " ${TSTORMS_DIR}
else
    mkdir -p ${TSTORMS_DIR}
fi
#
# now, do the installing:
#export NCO_DIR=${NCO_DIR}
#
echo "do the installing to: ${TSTORMS_DIR}"
#
export FC=$FC
export LD=$LD
#echo "*** NETCDF: ${NETCDF_FORTRAN_DIR}"
#export NETCDF_FFLAGS="-I${NETCDF_FORTRAN_DIR}/include -I${NETCDF_FORTRAN_DIR}/lib "
#BOOGER="`nc-config --fflags` -I. -I${NCO_DIR}/include -I/usr/local/include -I/usr/include -fltconsistency -stancck_temps -safe_cray_ptr -ftz -i_dynamic -assume byterecl -g -i4 -r8 -O2 -nowarn -Wp,-w"
#export FFLAGS=${BOOGER}
#echo "** ** ** ${FFLAGS}"
#echo "** *** ** `nc-config --fflags`"
#export LDFLAGS="-limf -lm -lpthread -L${NCO_DIR}/lib -L." `nc-config --flibs`

#echo "*** FFLAGS: ${FFLAGS}"
#echo "*** LDFLAGS: ${LDFLAGS}"

#
cd ${TSTORMS_SRC}/tstorms_driver
echo "install tstorms_driver:: `pwd` "
#make Makefile_compscript clean
#make Makefile_compscript
make clean
make
#
echo "  ***"|
echo " ** **"
echo "  ***"
cd ${TSTORMS_SRC}/trajectory_analysis
echo "install trajectory_analysis:: `pwd` "
#make Makefile_compscript clean
#make Makefile_compscript
make clean
make
# cd ${TSTORMS}/trajectory_analysis
#
cp -rf ${TSTORMS_SRC}  ${TSTORMS_DIR}/

#

