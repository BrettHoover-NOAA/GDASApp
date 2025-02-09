#!/bin/bash
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:         exgdas_global_marine_analysis_run.sh
# Script description:  Runs the global marine analysis with SOCA
#
# Author: Guillaume Vernieres        Org: NCEP/EMC     Date: 2022-04-24
#
# Abstract: This script makes a global model ocean sea-ice analysis using SOCA
#
# $Id$
#
# Attributes:
#   Language: POSIX shell
#   Machine: Orion
#
################################################################################

#  Set environment.
export VERBOSE=${VERBOSE:-"YES"}
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi

#  Directories
pwd=$(pwd)

#  Utilities
export NLN=${NLN:-"/bin/ln -sf"}

function socaincr2mom6 {
  incr=$1
  bkg=$2
  grid=$3
  incr_out=$4

  scratch=scratch_socaincr2mom6
  mkdir -p $scratch
  cd $scratch
  cp $incr inc.nc                   # TODO: I don't think we need to make a copy
  ncrename -d zaxis_1,Layer inc.nc  # Rename zaxis_1 to Layer
  ncks -A -C -v h $bkg h.nc         # Get h from background and rename axes to be consistent with inc.nc
  ncrename -d time,Time -d zl,Layer -d xh,xaxis_1 -d yh,yaxis_1 h.nc
  ncks -A -C -v h h.nc inc.nc       # Replace h incrememnt (all 0's) by h background
  ncks -A -C -v lon $grid inc.nc    # Add longitude
  ncks -A -C -v lat $grid inc.nc    # Add latitude
  mv inc.nc $incr_out
}

function bump_vars()
{
    tmp=$(ls -d ${1}_* )
    lov=()
    for v in $tmp; do
        lov[${#lov[@]}]=${v#*_}
    done
    echo "$lov"
}

function concatenate_bump()
{
    bumpdim=$1
    # Concatenate the bump files
    vars=$(bump_vars $bumpdim)
    n=$(wc -w <<< "$vars")
    echo "concatenating $n variables: $vars"
    lof=$(ls ${bumpdim}_${vars[0]})
    echo $lof
    for f in $lof; do
        bumpbase=${f#*_}
        output=bump/${bumpdim}_$bumpbase
        lob=$(ls ${bumpdim}_*/*$bumpbase)
        for b in $lob; do
            ncks -A $b $output
        done
    done
}

function clean_yaml()
{
    mv $1 tmp_yaml;
    sed -e "s/'//g" tmp_yaml > $1
}

################################################################################
# generate soca geometry
# TODO (Guillaume): Should not use all pe's for the grid generation
# TODO (Guillaume): Does not need to be generated at every cycles, store in static dir?
$APRUN_OCNANAL $JEDI_BIN/soca_gridgen.x gridgen.yaml > gridgen.out 2>&1

################################################################################
# Generate the parametric diag of B
$APRUN_OCNANAL $JEDI_BIN/soca_convertincrement.x parametric_stddev_b.yaml > parametric_stddev_b.out 2>&1
################################################################################
# Set decorrelation scales for bump C
$APRUN_OCNANAL $JEDI_BIN/soca_setcorscales.x soca_setcorscales.yaml > soca_setcorscales.out 2>&1

# 2D C from bump
yaml_list=`ls soca_bump2d_C*.yaml`
for yaml in $yaml_list; do
    # TODO (G, C, R, ...): problem with ' character when reading yaml, removing from file for now
    clean_yaml $yaml
    $APRUN_OCNANAL $JEDI_BIN/soca_error_covariance_training.x $yaml 2>$yaml.err
done
concatenate_bump 'bump2d'

# 3D C from bump
yaml_list=`ls soca_bump3d_C*.yaml`
for yaml in $yaml_list; do
    clean_yaml $yaml
    $APRUN_OCNANAL $JEDI_BIN/soca_error_covariance_training.x $yaml 2>$yaml.err
done
concatenate_bump 'bump3d'

################################################################################
# run 3DVAR FGAT
clean_yaml var.yaml
$APRUN_OCNANAL $JEDI_BIN/soca_var.x var.yaml > var.out 2>&1


# increments update for MOM6
# Note: ${DATA}/INPUT/MOM.res.nc points to the MOM6 history file from the start of the window
#       and is used to get the valid vertical geometry of the increment
( socaincr2mom6 `ls -t ${DATA}/Data/ocn.*3dvar*.incr* | head -1` ${DATA}/INPUT/MOM.res.nc ${DATA}/soca_gridspec.nc ${DATA}/Data/inc.nc )



################################################################################
set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err

################################################################################
