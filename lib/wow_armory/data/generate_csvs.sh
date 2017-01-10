#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${SCRIPT_DIR} > /dev/null

mkdir -p csv_temp
cd csv_temp
git clone https://github.com/simulationcraft/simc.git simc

pushd simc > /dev/null
git checkout legion-dev
popd

mv simc/dbc_extract3 simc/casc_extract .
rm -rf simc

mkdir -p casc_data
cd casc_extract
./casc_extract.py -m batch --cdn -o ../casc_data | tee ../casc_data/extract.log
cd ..

CDN_VERSION=`awk -F": " '/^Current build version/ {print $2}' casc_data/extract.log | awk '{print $1}'`
BUILD_NUMBER=`echo $CDN_VERSION | awk -F. '{print $NF}'`
CASC_DATA_DIR="${PWD}/casc_data/${CDN_VERSION}/DBFilesClient"

mkdir -p csvs
cd dbc_extract3
for i in ItemBonus ItemNameDescription SpellItemEnchantment RandPropPoints ItemUpgrade RulesetItemUpgrade ArtifactPowerRank; do
    echo "Generating CSV for $i..."
    ./dbc_extract.py -b ${BUILD_NUMBER} -p ${CASC_DATA_DIR} -t csv --delim=, $i > ../csvs/${i}.dbc.csv
done

cd $SCRIPT_DIR
mv csv_temp/csvs/*.csv .
rm -rf csv_temp

echo "Regenerate these files with the 'generate_csv.sh' script" > README.txt
echo >> README.txt
echo "Current files generated on `date` for build ${CDN_VERSION}" >> README.txt

popd > /dev/null
