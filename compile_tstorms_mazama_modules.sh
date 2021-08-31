#! /bin/bash

#SBATCH -n 1
#SBATCH -o tstorms_compile_out.out
#SBATCH -e tstorms_compile_out.err
#
# set up modules, compile variables, etc.
module purge
module unuse /usr/local/modulefiles

#MOD_COMPILER="gnu/8"
#COMP="gnu8"
#
MOD_COMPILER="intel/19"
COMP_PREREQ="intel/19.1.0.166"
COMP="intel19"

#MOD_MPI="mpich_3/"
#MPI_PREREQ="mpich/3.3.1"
#MPI=mpich3

MOD_MPI="openmpi_3/"
MPI="openmpi3"
MPI_PREREQ="openmpi_3/3.1.4"

MOD_MPI="impi_19/"
MPI="impi19"
MPI_PREREQ="impi_19/19.1.0.166"
#
# NOTE: At this time, the Makefile and/or mkmf template are specifically configured for ifort (and other intel things), and there is not a Cmake or ./configure
#  config., so the gnu compiler breaks on bad options. so for now, let's just skip gnu compiling.
module load ${MOD_COMPILER}
module load ${MOD_MPI}
###############################

#
COMP_MPI=${COMP}_${MPI}
###################
#
module load netcdf/
module load netcdf-fortran/
module load nco
#
module load autotools
#
echo "module list: "
module list
#
CC=${MPICC}
CXX=${MPICXX}
LD=${FC}
FC=${MPIFC}
#
# set this to your prefered path:
#TARGET_PATH_ROOT="/share/cees/software"
TARGET_PATH_ROOT=${SCRATCH}/.local/jss
#TARGET_PATH_ROOT=`pwd`/.local

ROOT_DIR=`pwd`
echo "root dir: ${ROOT_DIR}"
#
# Set this value; if you are ok with the subsequent directory structure, you can leave the rest alone. eventually
#  we'll want smarter version management.
#
###############################################
# Which parts do we do?
#  This is mostly a relic of the original development script. We include a couple of dependencies,
#  nominlaly in the event that we want to port this to a different system.
# TODO: separate these installations? Manage HDF4, NCO separately? Maybe for now, we create the NCO, HDF4 SW and reference
#  this script; parse it out later, if the time comes that we need to do that?
DO_TSTORMS=1
DO_MODULE=0
###############################################
#
TSTORMS="tropical_storms_pub"
TSTORMS_TAR="TSTORMS.tar.gz"
TSTORMS_SRC="${ROOT_DIR}/${TSTORMS}"
#VER="1.0.0"
VER="1.1.0"
#
# Target Path:
TSTORMS_DIR=${TARGET_PATH_ROOT}/tstorms/${COMP_MPI}/${VER}
MODULE_PATH="/share/cees/modules/moduledeps/${COMP}-${MPI}/tstorms"
#
C_FLAGS="-fpic `nc-config --cflags` -I${MPI_DIR}/include "
#CPP_FLAGS="-I${HDF5_INC} "
#CPP_FLAGS="`nc-config --cflags` -I${MPI_DIR}/include"
#echo "** ** ** CPP_FLAGS: ${CPP_FLAGS}"
#
export FFLAGS=" -fpic $(nf-config --fflags) $(nc-config --fflags) -fp-model strict -stack_temps -safe_cray_ptr -ftz -assume byterecl -g -i4 -r8 -O2 -nowarn -Wp,-w "
#
echo "** * * ** FFLAGS: ${FFLAGS}"

#
export LDFLAGS=" $(nc-config --flibs) $(nc-config --libs)  -L${HDF5_LIB} -L${MPI_DIR}/lib "
echo "*** LD_FLAGS: ${LDFLAGS}"
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
    # NOTE: for v1.1 (which is what we're calling it... we need to get the new ts_tools.f90 and trajectory.f90 code modules .
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
#
cd ${TSTORMS_SRC}/tstorms_driver
echo "doing make for tstorms_driver:: `pwd` "
#
make clean
make
#
echo "  ***"|
echo " ** **"
echo "  ***"
cd ${TSTORMS_SRC}/trajectory_analysis
echo "doing make for trajectory_analysis:: `pwd` "
#
make clean
make
#
cp -rf ${TSTORMS_SRC}  ${TSTORMS_DIR}/
#
#################
# now, write a module:
if [[ ${DO_MODULE} -eq 1 ]]; then
echo "Write module to: ${MODULE_PATH}/${VER}.lua"
if [[ ! -d ${MODULE_PATH} ]]; then mkdir -p ${MODULE_PATH} ; fi
#
cat > ${MODULE_PATH}/${VER}.lua <<EOF
-- -*- lua -*-
--
prereq("${COMP_PREREQ}")
prereq("${MPI_PREREQ}")
--
depends_on("netcdf")
depends_on("netcdf-fortran")
--
-- NOTE: NCO will load hdf4, and i believe it is NCO that requires HDF4, so this is appropriate...
depends_on("nco/")
--
whatis("TSTORMS SW package, built on the ${COMP} - ${MPI} toolchhain.")
--
--
TSTORMS_DIR = "${TSTORMS_DIR}/tropical_storms_pub_v1_1"
TSTORMS_TRAJECTORY_DIR =  pathJoin(TSTORMS_DIR, 'trajectory_analysis')
TSTORMS_DRIVER_DIR = pathJoin(TSTORMS_DIR, 'tstorms_driver')
--
pushenv("TSTORMS_DIR", TSTORMS_DIR)
pushenv("TSTORMS_TRAJECTORY_DIR", TSTORMS_TRAJECTORY_DIR)
pushenv("TSTORMS_DRIVER_DIR", TSTORMS_DRIVER_DIR)
--
prepend_path("PATH", TSTORMS_DIR)
prepend_path("PATH", TSTORMS_TRAJECTORY_DIR)
prepend_path("PATH", TSTORMS_DRIVER_DIR)
--
--

EOF
#
fi
