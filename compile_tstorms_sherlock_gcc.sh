#!/bin/bash
#
#SBATCH --job-name=compile_tstorms
#SBATCH --partition=serc
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=12:00:00
#SBATCH --constraint=CPU_MNF:AMD
#SBATCH --output=seissol_spack_compile_%j.out
#SBATCH --error=seissol_spack_compile_%j.err
#
# WHAT IS THIS?
# Compile script for tstorms on Stanford's Sherlock HPC. This script *attempts* to build TSTORMS using Sherlock's stock modules and SW,
#  and in particular using the gcc compiler. There are a few tricks, for example:
#  1. TSTORMS  ships with a Makefile and mkmf_template (which is just included into Makefile) that specifies intel compiler flags. Frankly, I don't really
#   know what they do or if they need to be matched in gcc, or which ones can just be skipped, or...
#  2. Sherlock standard SW modules don't have a cohesive stack of gcc+mpi+netcdf+nco, so i hacked the nco/5.0.6 module to use a netcdf-c/4.9 installation,
#    instead of a different netcdf/4.8.8 (I think). Which should be fine...
#
# NOTE: you might not want to just run this as-is. You may want to change some build paths, etc. If you are building somewhere other than Sherlock, you'll
#  likely need to fill out your dependencies. Namely, netcdf-fortran also loads:
#  - gcc/10.1.0
#  - openmpi/4.
#  - hdf5/
#  - szip/
#  - curl/
#  - libxml/
#  - pnetcdf/
#  - netcdf-c
#  - netcdf-fortran
#
# and those may also load some dependencies.
#
module purge
#
#module use $HOME/.local/modulefiles
#
module load devel system physics
# this will load the whole gcc/10.1 stack above it...
module load netcdf-fortran/
# hacking nco to allow fortran-c/4.9 , which makes a bunch of other dependencies work... so let's just transcribe it's parts here:
#module --ignore-cache load nco-local/5.0.6
  module load gsl/2.7
  module load udunits/2.2.26
  module load antlr/2.7.7
  NCO_PATH="/share/software/user/open/nco/5.0.6"
  PATH=${NCO_PATH}/bin:${PATH}
  LIBRARY_PATH=${NCO_PATH}/lib:${LIBRARY_PATH}
  LD_LIBRARY_PATH=${NCO_PATH}/lib:${LD_LIBRARY_PATH}
  CPATH=${NCO_PATH}/include:${CPATH}
module load libevent/
module load cmake/

# set up x86 architecture (we're probably going to hafe to recompile this on a new stack before too long...).
#
#. /home/groups/s-ees/share/cees/spack_cees/scripts/cees_sw_setup-beta.sh x86
#module purge
#
#module load intel-cees-beta/
#module load mpich-cees-beta/
#module load netcdf-c-cees-beta/
#module load netcdf-fortran-cees-beta/
#module load nco-cees-beta/
#module load cmake/
#
NCPUS=1
if [[ ! -z ${SLURM_CPUS_PER_TASK} ]]; then
  NCPUS=${SLURM_CPUS_PER_TASK}
fi
#
echo "Compilers: "
echo "FC: $FC, CC: $CC, CXX: $CXX"
echo "DEBUG: `which $FC`"
echo "DEBUG: `$FC --version`"
#
#ROOT_PATH=`pwd`
#BUILD_PATH=$(dirname ${ROOT_PATH})/tstorms_build_gcc
BUILD_PATH=${SCRATCH}/tstorms_buld_gcc
TSTORMS_SRC_PATH=${BUILD_PATH}/tropical_storms_pub
TSTORMS_TAR="TSTORMS.tar.gz"
TSTORMS_VER="1.1.0"
TSTORMS_INSTALL_PREFIX="/home/groups/s-ees/share/cees/software/no_arch/tstorms/${TSTORMS_VER}"
#
if [[ ! -d ${TSTORMS_INSTALL_PREFIX}/bin ]]; then
  mkdir -p ${TSTORMS_INSTALL_PREFIX}/bin
fi
#
# derive some working dirs from SW:
MPI_DIR=$(dirname $(dirname $(which mpicc)))
HDF5_DIR=$(dirname $(dirname $(which gif2h5)))
HDF5_INC=${HDF5_DIR}/include
HDF5_LIB=${HDF5_DIR}/lib
#
if [[ ! -d ${BUILD_PATH} ]]; then
  mkdir -p ${BUILD_PATH}
fi
#
# NOTE: building NCO throws some sort of linking error in ANTLR. Let's see if we can just use Sherlock's NCO...
#cd ${BUILD_PATH}
#  if [[ ! -d nco ]]; then git clone --recursive --recursive git@github.com:nco/nco.git
#fi
## TODO: did we actually build it? PREFIX= ?
#cd nco
#./configure LIBS="-L/share/software/user/open/antlr/2.7.7/lib -lantlr"
#make clean
#make -j ${NCPUS}

#
cd ${BUILD_PATH}
if [[ ! -f ${TSTORMS_TAR} ]] ; then 
  echo "wget TSTORMS.."
  wget ftp://ftp.gfdl.noaa.gov/perm/GFDL_pubrelease/TSTORMS/TSTORMS.tar.gz
fi
#
if [[ ! -d ${TSTORMS_SRC_PATH} ]]; then
  echo "Untar TSTORMS..."
  tar xvf ${TSTORMS_TAR}
fi 
#
# Some flags...
CPPFLAGS="-I/usr/local/include"
C_FLAGS="-fpic `nc-config --cflags` -I${MPI_DIR}/include "
#CPP_FLAGS="-I${HDF5_INC} "
#CPP_FLAGS="`nc-config --cflags` -I${MPI_DIR}/include"
#echo "** ** ** CPP_FLAGS: ${CPP_FLAGS}"
#
#export FFLAGS=" -fpic $(nf-config --fflags) $(nc-config --fflags) -fp-model strict -stack_temps -safe_cray_ptr -ftz -assume byterecl -g -i4 -r8 -O2 -nowarn -Wp,-w "
# Intel:
#FFLAGS=" ${CPPFLAGS} -fpic -fltconsistency -stack_temps -safe_cray_ptr -ftz -i_dynamic -assume byterecl -g -i4 -r8 -O2 -nowarn -Wp,-w"
# gcc?
FFLAGS=" ${CPPFLAGS} -fpic $(nf-config --fflags) $(nc-config --fflags) -g -O2 -Wp,-w -ffree-line-length-512"
echo "** * * ** FFLAGS: ${FFLAGS}"
#
#LDFLAGS=" $(nc-config --flibs) $(nc-config --libs)  -L${HDF5_LIB} -L${MPI_DIR}/lib "
LDFLAGS=" $(nc-config --flibs) $(nc-config --libs)  -L${HDF5_LIB} $(pkg-config --libs ${MPI_DIR}/lib/pkgconfig/ompi-fort.pc) "
# from original:
#LDFLAGS="${LDFLAGS} -limf -lm -lpthread -lrt -lhdf5 -lhdf5_hl"
LDFLAGS="${LDFLAGS}  -lm -lpthread -lrt -lhdf5 -lhdf5_hl"

echo "*** LD_FLAGS: ${LDFLAGS}"
#
# *** TSTORMS_DRIVER:
cd ${TSTORMS_SRC_PATH}/tstorms_driver
echo "*******  *************  **************"
echo "DEBUG: doing make for tstorms_driver:: `pwd` "
#
# copy Makefile and update to comment out the mkmf_template "include" reference.
cp -f Makefile Makefile_gcc
sed -i 's/include mkmf/#include mkmf/g' Makefile_gcc
#
CPPFLAGS=$CPPFLAGS FC=$FC LD=$FC CFLAGS=$C_FLAGS FFLAGS=$FFLAGS LDFLAGS=$LDFLAGS make -f Makefile_gcc clean
CPPFLAGS=$CPPFLAGS FC=$FC LD=$FC CFLAGS=$C_FLAGS FFLAGS=$FFLAGS LDFLAGS=$LDFLAGS make -f Makefile_gcc
#
cp tstorms_driver.exe ${TSTORMS_INSTALL_PREFIX}/bin
#
# ** TRAJECTORY_ANALYSIS:
cd ${TSTORMS_SRC_PATH}/trajectory_analysis
echo "*******  *************  **************"
echo "DEBUG: doing make for trajectory_analysis:: `pwd` "
#
# copy Makefile and update to comment out the mkmf_template "include" reference.
cp -f Makefile Makefile_gcc
sed -i 's/include mkmf/#include mkmf/g' Makefile_gcc
#
CPPFLAGS=$CPPFLAGS FC=$FC LD=$FC CFLAGS=$C_FLAGS FFLAGS=$FFLAGS LDFLAGS=$LDFLAGS make -f Makefile_gcc clean
CPPFLAGS=$CPPFLAGS FC=$FC LD=$FC CFLAGS=$C_FLAGS FFLAGS=$FFLAGS LDFLAGS=$LDFLAGS make -f Makefile_gcc
#
for fl in dotraj_new.m imask_2 landsea.map startup.m trajectory_analysis_csc.exe
do
  cp ${fl} ${TSTORMS_INSTALL_PREFIX}/bin/
done

cd ${BUILD_PATH}
