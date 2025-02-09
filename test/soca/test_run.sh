#!/bin/bash
set -e

project_binary_dir=$1
project_source_dir=$2

source ${project_source_dir}/test/soca/test_utils.sh

# Clean test files created during a previous test
echo "============================= Test that the grid has been generated"
rm -f ${project_binary_dir}/test/soca/3dvar/analysis/soca_gridspec.nc
rm -f  ${project_binary_dir}/test/soca/3dvar/analysis/ocn.bkgerr_stddev.incr.2018-04-15T09:00:00Z.nc
rm -f  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.iter1.incr.2018-04-15T09:00:00Z.nc
rm -f  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.incr.2018-04-15T09:00:00Z.nc
rm -f  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.an.2018-04-15T09:00:00Z.nc
rm -f  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.an.2018-04-15T12:00:00Z.nc
rm -f  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.an.2018-04-15T15:00:00Z.nc
rm -f  ${project_binary_dir}/test/soca/3dvar/analysis/Data/inc.nc

# Export runtime env. variables
source ${project_source_dir}/test/soca/runtime_vars.sh $project_binary_dir $project_source_dir

# Run step
echo "============================= Testing exgdas_global_marine_analysis_run.sh for clean exit"
${project_source_dir}/scripts/exgdas_global_marine_analysis_run.sh > exgdas_global_marine_analysis_run.log

echo "============================= Test that the grid has been generated"
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/soca_gridspec.nc

echo "============================= Test that the parametric diag of B was generated"
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/ocn.bkgerr_stddev.incr.2018-04-15T09:00:00Z.nc

echo "============================= Test that an increment and an analysis were created"
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.iter1.incr.2018-04-15T09:00:00Z.nc
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.incr.2018-04-15T09:00:00Z.nc
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.an.2018-04-15T09:00:00Z.nc
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.an.2018-04-15T12:00:00Z.nc
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/Data/ocn.3dvarfgat_pseudo.an.2018-04-15T15:00:00Z.nc
test_file  ${project_binary_dir}/test/soca/3dvar/analysis/Data/inc.nc
