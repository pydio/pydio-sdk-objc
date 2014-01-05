#This script initializes repository specific files, this includes:
# git submodules
# OCMockito and OCHamcrest as "frameworks"
set -e

echo "*** Updating git submodules ***"
git submodule update --init

BASEDIR=`pwd`
PYDIOBASEDIR=${BASEDIR}/PydioSDK
FRAMEWORKS=${PYDIOBASEDIR}/Frameworks

rm -rf ${FRAMEWORKS}/*
mkdir ${FRAMEWORKS}

LIBRARIESDIR=${PYDIOBASEDIR}/Libraries
OCHAMCRESTDIR=${LIBRARIESDIR}/OCHamcrest
OCMOCKITODIR=${LIBRARIESDIR}/OCMockito

echo "*** Building OCHamcrest \"framework\" ***"
cd ${OCHAMCRESTDIR}
git submodule update --init 
cd Source
./MakeDistribution.sh
#To build OCMockito
cp -r build/OCHamcrest-3.0.1 ${OCMOCKITODIR}/Frameworks
rm -rf ${OCMOCKITODIR}/Frameworks/OCHamcrest-3.0.0
ln -s ${OCMOCKITODIR}/Frameworks/OCHamcrest-3.0.1 ${OCMOCKITODIR}/Frameworks/OCHamcrest-3.0.0
#For Project
cp -r build/Release/OCHamcrestIOS.framework ${FRAMEWORKS}/

echo "*** Updating git submodules for OCMockito ***"
cd ${OCMOCKITODIR}
git submodule update --init
cd Source
./MakeDistribution.sh
cp -r build/Release/OCMockitoIOS.framework ${FRAMEWORKS}/

