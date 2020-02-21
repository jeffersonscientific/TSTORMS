#!/bin/csh
#SBATCH -n 1
#SBATCH -o mima_compile.out
#SBATCH -e mima_compile.err
#
#Minimal runscript for atmospheric dynamical cores
#
# Mazama:
# from prefix: /opt/ohpc/pub/moduledeps/intel
#
# get proper compiler (intel), mpi environment:
module purge
module unuse /usr/local/modulefiles
#
module load intel/19.1.0.166
#
#module load mvapich2/2.3.2
#module load openmpi3
module load mpicch/3
#
module load netcdf/4.7.1
module load netcdf-fortran/4.5.2
#module load netcdf-cxx/4.3.1
#module load pnetcdf/1.12.0
#
# borrowning from the MiMA compile script, these variables would be used
#  to parametrize mkmf. but I think we're going to skip that and just set environment
#  variables?
export platform=Mazama
export template=`pwd`/mkmf_template_tstorms_driver_${platform}
export execdir=`pwd`/exec.${platform}
#
echo "*** trying mkmf..."
cd $execdir
#
# ?? from MiMA script:
# export cppDefs="-Duse_libMPI -Duse_netCDF -DgFortran"
#
$
