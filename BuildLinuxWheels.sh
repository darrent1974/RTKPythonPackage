#!/bin/bash

# This script should lie in a directory alongside with the RTK sources
cd RTK

export ITK_PACKAGE_VERSION=v4.13.1.post1

# Remove call to the build script to only perform the download step.
# This allows for altering the cache in case sources are not up-to-date  
replace_line="./ITKPythonPackage/scripts/dockcross-manylinux-build-module-wheels.sh"
sed -i -e "s|$replace_line||g" \
  dockcross-manylinux-download-cache-and-build-module-wheels.sh

if [[ ! -d ITKPythonPackage ]]; then
  ./dockcross-manylinux-download-cache-and-build-module-wheels.sh
fi

# Apply patch from https://github.com/InsightSoftwareConsortium/ITK/commit/83801da92519a49934b265801d303a6531856b50
after_line="set(image \"\${ITKN_\${name}}\")"
additional_command="if(image STREQUAL \"\")\n      string(REPLACE \"I\" \"itkImage\" imageTemplate \${name})\n      set(image \${imageTemplate})\n    endif()"
sed -i -e "s|$after_line|$after_line\n    $additional_command|g" \
  ITKPythonPackage/standalone-x64-build/ITK-source/Wrapping/Generators/Python/CMakeLists.txt

# Add CMake options for building the module
after_line='-DBUILD_TESTING:BOOL=OFF \\'

rtk_build_applications='-DRTK_BUILD_APPLICATIONS:BOOL=OFF \\'
sed -i -e "s|$after_line|$after_line\n      $rtk_build_applications|g" \
  ITKPythonPackage/scripts/internal/manylinux-build-module-wheels.sh

if [ $ITK_PACKAGE_VERSION == v4.13.1.post1 ]; then
  echo 'Building against ITK v4.13.1.post1 Adding -std=c++11 flag.. ' 1>&2
  cmake_cxx_flags='-DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -std=c++11" \\'
  sed -i -e "s|$after_line|$after_line\n      $cmake_cxx_flags|g" \
    ITKPythonPackage/scripts/internal/manylinux-build-module-wheels.sh
fi

# Finally build Linux wheels
#./ITKPythonPackage/scripts/dockcross-manylinux-build-module-wheels.sh

# Run this script to build the Python wheel packages for Linux for an ITK
# external module.
#
# Versions can be restricted by passing them in as arguments to the script
# For example,
#
#   scripts/dockcross-manylinux-build-module-wheels.sh cp27mu cp35

# Pull dockcross manylinux images
docker pull dockcross/manylinux-x64

# Generate dockcross scripts
docker run dockcross/manylinux-x64 > /tmp/dockcross-manylinux-x64
chmod u+x /tmp/dockcross-manylinux-x64

script_dir=$(cd $(dirname $0) || exit 1; pwd)

# Build wheels
mkdir -p dist
DOCKER_ARGS="--rm -v $(pwd)/dist:/work/dist/ -v $script_dir/..:/ITKPythonPackage -v $(pwd)/tools:/tools -v  $script_dir/../../cuda-80:/cuda80"
echo "DOCKER_ARGS = " $DOCKER_ARGS
/tmp/dockcross-manylinux-x64 \
  -a "$DOCKER_ARGS" \
  "/ITKPythonPackage/scripts/internal/manylinux-build-module-wheels.sh" "$@"

