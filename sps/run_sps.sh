#!/bin/bash
[[ "$1" == -v* ]] && set -x
#
[[ -d SHM ]]       || { echo "ERROR: directory SHM not found" ; exit 1 ;}
mkdir -p SHM/storage_model SHM/Data/Input/inrep
#
[[ -d Data ]]      || { echo "ERROR: directory Data not found" ; exit 1 ; }
[[ -d Data_disk ]] || { echo "ERROR: directory Data_disk not found" ; exit 1 ; }
#
[[ -f Data/Input/climato ]]        || { echo "INFO: copying climato" ; cp -f Data_disk/Input/climato Data/Input ; }
[[ -f Data/Input/Gem_geophy.fst ]] || { echo "INFO: copying Gem_geophy.fst" ; cp -f Data_disk/Input/Gem_geophy.fst Data/Input ; }
#
rm -f Data/Input/inrep/anal
ln -s ../anal Data/Input/inrep/anal
#
if [[ -d storage_model ]] ; then
  storage_model=$(readlink -e storage_model)
fi
grep -q storage_model exper.cfg || echo "storage_model=${storage_model}" >>./exper.cfg
export storage_model
#
[[ -r exper.cfg ]] || { echo "ERROR: cannot find $(pwd -P)/exper.cfg" ; exit 1 ; }
source ./exper.cfg
#
# make sure that there is a value for exper_current_date, exper_fold_date and storage_model in configuration file
#
[[ -z ${exper_current_date} ]] && exper_current_date=${exper_start_date} && echo "exper_current_date=${exper_current_date}" >>exper.cfg
#
[[ -z ${exper_fold_date} ]] && exper_fold_date="$(date -d${exper_end_date}+1year  +%Y%m%d)" && echo "exper_fold_date=${exper_fold_date}" >>./exper.cfg
#
[[ -d "${storage_model}" ]] || { echo "ERROR: ${storage_model} does not exist" ; exit 1 ; }
#
while true
do
  source ./exper.cfg
  #########################################################################
  #  if we reached a back to the past point, update exper_current_date
  #  resetting it to exper_start_date, make sure to set
  #  back to the past flag so that pre_sps.sh will force dates of validity
  #########################################################################
  #
  if [[ "${exper_current_date}" == "${exper_end_date}" ]] ; then
    echo "INFO: last date reached: ${exper_end_date}"
    exit 0
  fi
  #
  pre_sps.sh  || { echo "ERROR: pre_sps failed" ; exit 1 ; }
  #
  echo "INFO: sps.ksh ${exper_cpu_config}"
  sps.ksh ${exper_cpu_config} >sps_${exper_current_date:-${exper_start_date}}.lst 2>&1 || { echo "ERROR: sps.ksh failed" ; exit 1 ; }
  #
  post_sps.sh  || { echo "ERROR: post_sps failed" ; exit 1 ; }
  #
done
