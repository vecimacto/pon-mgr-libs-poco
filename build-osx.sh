#!/usr/bin/env bash

rm -rf cmake-build
mkdir -p cmake-build
cd cmake-build

PGROOT="$(brew --prefix libpq)"
SQLROOT="$(brew --prefix sqlite)"

# Strong, combined CMake config:
cmake .. -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_PREFIX_PATH="/opt/homebrew" \
  -DCMAKE_IGNORE_PATH="/usr/local;/Library/Frameworks" \
  -DCMAKE_FIND_FRAMEWORK=NEVER \
  -DPOCO_UNBUNDLED=ON \
  -DPOCO_ENABLE_DATA=ON \
  -DPOCO_ENABLE_DATA_POSTGRESQL=ON \
  -DPOCO_ENABLE_SQLITE=ON \
  -DPostgreSQL_ROOT="$PGROOT" \
  -DPostgreSQL_INCLUDE_DIR="$PGROOT/include" \
  -DPostgreSQL_LIBRARY="$PGROOT/lib/libpq.dylib" \
  -DSQLite3_ROOT="$SQLROOT" \
  -DSQLite3_INCLUDE_DIR="$SQLROOT/include" \
  -DSQLite3_LIBRARY="$SQLROOT/lib/libsqlite3.dylib" \
  -DCMAKE_INSTALL_RPATH="$PGROOT/lib;$SQLROOT/lib;/opt/homebrew/lib"

make -j