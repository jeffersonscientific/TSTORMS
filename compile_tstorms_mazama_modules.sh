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
module load intel/19
COMP="intel19"

MOD_MPI="mpich_3/"
MPI=mpich3

#MOD_MPI="openmpi_3/"
#MPI="openmpi3"
#MOD_MPI="impi_19/"
#MPI="impi19"
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
module load netcdf
module load netcdf-fortran

# share modules:
#module load hdf4
module load nco
#
module load autotools
#module load cmake
#
echo "module list: "
module list
#

#
#
# set this to your prefered path:
TARGET_PATH_ROOT="/share/cees/software"
#TARGET_PATH_ROOT=${SCRATCH}/.local
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
DO_HDF4=0
DO_NCO=0
DO_TSTORMS=1
###############################################
#
#TSTORMS="tropical_storms_pub"
TSTORMS="tropical_storms_pub_v1_1"
TSTORMS_TAR="TSTORMS.tar.gz"
TSTORMS_SRC="${ROOT_DIR}/${TSTORMS}"
#VER="1.0.0"
VER="1.1.0"
#
# Target Path:
TSTORMS_DIR=${TARGET_PATH_ROOT}/tstorms/${COMP_MPI}/${VER}
MODULE_PATH="/share/cees/modules/moduledeps/${COMP}-${MPI}/tstorms"
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
LD_FLAGS="`nc-config --libs` `nc-config --flibs`  -L${HDF5_LIB} -L${MPI_DIR}/lib"
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
#echo "*** NETCDF: ${NETCDF_FORTRAN_DIR}"
#export NETCDF_FFLAGS="-I${NETCDF_FORTRAN_DIR}/include -I${NETCDF_FORTRAN_DIR}/lib "
#BOOGER="`nc-config --fflags` -I. -I${NCO_DIR}/include -I/usr/local/include -I/usr/include -fltconsistency -stancck_temps -safe_cray_ptr -ftz -i_dynamic -assume byterecl -g -i4 -r8 -O2 -nowarn -Wp,-w"
#export FFLAGS=${BOOGER}
#echo "** ** ** ${FFLAGS}"
#echo "** *** ** `nc-config --fflags`"
#export LDFLAGS="-limf -lm -lpthread -L${NCO_DIR}/lib -L." `nc-config --flibs`
# so... we get a linking error, cannot find -limf.
#  libimf appears here:
# /opt/ohpc/pub/intel/compilers_and_libraries_2020.0.166/linux/compiler/lib/intel64_lin/libimf.so
# which we should be picking up from the module load intel/19...  but let's specify that (see make_templete_tstorms_mazama) -L and see how we go.

#echo "*** FFLAGS: ${FFLAGS}"
#echo "*** LDFLAGS: ${LDFLAGS}"

#
cd ${TSTORMS_SRC}/tstorms_driver
echo "doing make for tstorms_driver:: `pwd` "
#make Makefile_compscript clean
#make Makefile_compscript
make clean
make
#
echo "  ***"|
echo " ** **"
echo "  ***"
cd ${TSTORMS_SRC}/trajectory_analysis
echo "doing make for trajectory_analysis:: `pwd` "
#make Makefile_compscript clean
#make Makefile_compscript
make clean
make
# cd ${TSTORMS}/trajectory_analysis
#
cp -rf ${TSTORMS_SRC}  ${TSTORMS_DIR}/
#
# now, write a module:
echo "Write module to: ${MODULE_PATH}/${VER}.lua"
if [[ ! -d ${MODULE_PATH} ]]; then mkdir -p ${MODULE_PATH} ; fi
#
cat > ${MODULE_PATH}/${VER}.lua <<EOF
-- -*- lua -*-
--
prereq("${MOD_COMPILER}")
prereq("${MOD_MPI}")
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
TSTORMS_DIR = "${TSTORMS_DIR}"
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

