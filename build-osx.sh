#!/usr/bin/env bash

rm -rf cmake-build
mkdir -p cmake-build
cd cmake-build

PGROOT="$(brew --prefix libpq)"
SQLROOT="$(brew --prefix sqlite)"
MYROOT="$(brew --prefix mysql-client)"

cmake .. -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_PREFIX_PATH="/opt/homebrew" \
  -DCMAKE_IGNORE_PATH="/usr/local;/Library/Frameworks" \
  -DCMAKE_FIND_FRAMEWORK=NEVER \
  -DPOCO_UNBUNDLED=ON \
  -DPOCO_ENABLE_DATA=ON \
  -DPOCO_ENABLE_SQLITE=ON \
  -DPOCO_ENABLE_DATA_POSTGRESQL=ON \
  -DPOCO_ENABLE_DATA_MYSQL=ON \
  -DPostgreSQL_ROOT="$PGROOT" \
  -DPostgreSQL_INCLUDE_DIR="$PGROOT/include" \
  -DPostgreSQL_LIBRARY="$PGROOT/lib/libpq.dylib" \
  -DSQLite3_ROOT="$SQLROOT" \
  -DSQLite3_INCLUDE_DIR="$SQLROOT/include" \
  -DSQLite3_LIBRARY="$SQLROOT/lib/libsqlite3.dylib" \
  -DMYSQL_ROOT_DIR="$MYROOT" \
  -DMYSQL_INCLUDE_DIR="$MYROOT/include" \
  -DMYSQL_LIBRARY="$MYROOT/lib/libmysqlclient.dylib" \
  -DCMAKE_INSTALL_RPATH="$PGROOT/lib;$SQLROOT/lib;$MYROOT/lib;/opt/homebrew/lib"

make -j