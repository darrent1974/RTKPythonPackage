#!/usr/bin/env bash

# This script should lie in a directory alongside with the RTK sources
cd RTK

# install sed tool
brew update
brew install gnu-sed --with-default-names

# Fetch script from https://rawgit.com/InsightSoftwareConsortium/ITKPythonPackage
curl -L https://rawgit.com/InsightSoftwareConsortium/ITKPythonPackage/master/scripts/macpython-download-cache-and-build-module-wheels.sh -O
chmod u+x macpython-download-cache-and-build-module-wheels.sh

# Remove call to the build/install scripts to only perform the download step.
# This allows for altering the cache in case sources are not up-to-date  
replace_line="/Users/Kitware/Dashboards/ITK/ITKPythonPackage/scripts/macpython-build-module-wheels.sh \"\$\@\""
sed -i -e "s|$replace_line||g" \
  macpython-download-cache-and-build-module-wheels.sh

replace_line="/Users/Kitware/Dashboards/ITK/ITKPythonPackage/scripts/macpython-install-python.sh"
sed -i -e "s|$replace_line||g" \
  macpython-download-cache-and-build-module-wheels.sh

# Perform download step
./macpython-download-cache-and-build-module-wheels.sh

# Only install one python version to avoid timeout on TravisCI
command="for pyversion in \$LATEST_27; do"
replace_line="for pyversion in \$LATEST_27 \$LATEST_35 \$LATEST_36; do"
sed -i -e "s|$replace_line|$command|g" \
  /Users/Kitware/Dashboards/ITK/ITKPythonPackage/scripts/macpython-install-python.sh

# Perform python install step
/Users/Kitware/Dashboards/ITK/ITKPythonPackage/scripts/macpython-install-python.sh

# Force pip to upgrade
command="\${PYTHON_EXECUTABLE} -m pip install --upgrade pip"
after_line="PYTHON_EXECUTABLE=\${VENV}/bin/python"
sed -i -e "s|$after_line|$after_line\n      $command|g" \
  /Users/Kitware/Dashboards/ITK/ITKPythonPackage/scripts/macpython-build-module-wheels.sh

# Apply patch from https://github.com/InsightSoftwareConsortium/ITK/commit/83801da92519a49934b265801d303a6531856b50
after_line="set(image \"\${ITKN_\${name}}\")"
additional_command="if(image STREQUAL \"\")\n      string(REPLACE \"I\" \"itkImage\" imageTemplate \${name})\n      set(image \${imageTemplate})\n    endif()"
sed -i -e "s|$after_line|$after_line\n    $additional_command|g" \
  /Users/Kitware/Dashboards/ITK/ITKPythonPackage/standalone-build/ITK-source/Wrapping/Generators/Python/CMakeLists.txt

# Add CMake options for building the module
after_line='-DBUILD_TESTING:BOOL=OFF \\'

rtk_build_applications='-DRTK_BUILD_APPLICATIONS:BOOL=OFF \\'
sed -i -e "s|$after_line|$after_line\n      $rtk_build_applications|g" \
  /Users/Kitware/Dashboards/ITK/ITKPythonPackage/scripts/macpython-build-module-wheels.sh

# Finally build MacOS wheels
/Users/Kitware/Dashboards/ITK/ITKPythonPackage/scripts/macpython-build-module-wheels.sh 2.7

# Package wheels
tar -zcvf dist.tar.gz dist/
curl -F file="@dist.tar.gz" https://filebin.ca/upload.php