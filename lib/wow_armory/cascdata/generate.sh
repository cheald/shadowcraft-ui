#!/bin/sh

WORK_DIR=`pwd`
DBC_DIR="${WORK_DIR}/dbcs"

# clone the two tools that we need from simc to do this
echo "Retriving necessary tools from simulationcraft github"
wget https://github.com/simulationcraft/simc/archive/master.zip -O simc-master.zip
unzip simc-master.zip simc-master/casc_extract/*
unzip simc-master.zip simc-master/dbc_extract/*
echo

# Download the casc file from the Blizzard CDN using casc_extract
# TODO: get the build number as we download the data so that we can use it
# with dbc_extract later.
echo "Downloading current CASC data from Blizzard CDN"
cd simc-master/casc_extract
mkdir -p "${DBC_DIR}"
 ./casc_extract.py --cdn -m batch -o "${DBC_DIR}" | tee "${DBC_DIR}/casc_extract.log"
echo
cd "${WORK_DIR}"

BUILD_VERSION=`awk -F. '/Current build version/ {print $NF}' "${DBC_DIR}/casc_extract.log"`
CDN_VERSION=`awk '/Current CDN version/ {print $NF}' "${DBC_DIR}/casc_extract.log"`
echo "Build version: ${BUILD_VERSION}      CDN version: ${CDN_VERSION}"

# Generate the tables.  The build number here will change, but we got it earlier
# TODO: need other data files here, which are they?
echo "Extracting DBC data into JSON"
cd simc-master/dbc_extract
./dbc_extract.py -b ${BUILD_VERSION} -p "${DBC_DIR}/${CDN_VERSION}/DBFilesClient" -t item -o js > "${WORK_DIR}/Items.json"
cd "${WORK_DIR}"

# Clean up all of the things we don't need anymore
echo "Cleaning up"
rm -rf simc-master.zip
rm -rf simc-master
rm -rf dbcs
