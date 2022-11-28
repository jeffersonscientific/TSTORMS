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
module purge
#
# set up x86 architecture (we're probably going to hafe to recompile this on a new stack before too long...).
#
# script to compile TSTORMS on Stanford's Sherlock HPC, using cees-beta SW stack. Generall, don't recommend using this as it is, since
#  that SW stack will likely be retired. compile_tstorms_gcc.sh (or similar...) is a better option. It uses standard Sherlock SW and
#  gcc, not Intel, which is a bit easier to use and more universal, even if possibly less performant.
#
#
. /home/groups/s-ees/share/cees/spack_cees/scripts/cees_sw_setup-beta.sh x86
module purge
#
module load intel-cees-beta/
module load mpich-cees-beta/
module load netcdf-c-cees-beta/
module load netcdf-fortran-cees-beta/
module load nco-cees-beta/
module load cmake/

ROOT_PATH=`pwd`
BUILD_PATH=$(dirname ${ROOT_PATH})/tstorms_build
TSTORMS_SRC_PATH=${BUILD_PATH}/tropical_storms_pub
TSTORMS_TAR="TSTORMS.tar.gz"
#
if [[ ! -d ${BUILD_PATH} ]]; then
  mkdir -p ${BUILD_PATH}
fi
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

cd ${BUILD_PATH}
