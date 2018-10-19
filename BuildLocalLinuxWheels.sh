#!/bin/bash

git clone https://github.com/darrent1974/RTK.git RTK
cd RTK
git checkout PythonWrapping

curl -L https://raw.githubusercontent.com/InsightSoftwareConsortium/ITKPythonPackage/v4.13.1.post1/requirements-dev.txt -O
curl -L https://raw.githubusercontent.com/InsightSoftwareConsortium/ITKPythonPackage/v4.13.1.post1/scripts/dockcross-manylinux-download-cache-and-build-module-wheels.sh -O
chmod u+x dockcross-manylinux-download-cache-and-build-module-wheels.sh

cd ..
chmod u+x BuildLinuxWheels.sh
./BuildLinuxWheels.sh
