#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
POCO_SRC_DIR="${POCO_SRC_DIR:-$PWD}"            # Run this from the Poco source dir, or set POCO_SRC_DIR
BUILD_DIR="${BUILD_DIR:-$POCO_SRC_DIR/build}"   # Build directory
GENERATOR="${GENERATOR:-Unix Makefiles}"        # or "Ninja" if you prefer
BUILD_TYPE="${BUILD_TYPE:-Release}"             # Debug/RelWithDebInfo also fine

# ===== Ensure Apple Silicon Homebrew first =====
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

echo "== Toolchain =="
uname -m
clang --version | head -n1
brew --version | head -n1
echo

# ===== Install dependencies (arm64) =====
echo "== Installing Homebrew deps =="
brew update
brew install cmake pkg-config sqlite libpq mysql-client

# Optional: make keg-only clients visible to pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig:/opt/homebrew/opt/sqlite/lib/pkgconfig:/opt/homebrew/opt/mysql-client/lib/pkgconfig:/opt/homebrew/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Strong default include/lib/rpath hints toward /opt/homebrew (arm64)
export CPPFLAGS="-I/opt/homebrew/include -I/opt/homebrew/opt/libpq/include -I/opt/homebrew/opt/sqlite/include -I/opt/homebrew/opt/mysql-client/include ${CPPFLAGS:-}"
export LDFLAGS="-L/opt/homebrew/lib -L/opt/homebrew/opt/libpq/lib -L/opt/homebrew/opt/sqlite/lib -L/opt/homebrew/opt/mysql-client/lib -Wl,-rpath,/opt/homebrew/lib -Wl,-rpath,/opt/homebrew/opt/libpq/lib -Wl,-rpath,/opt/homebrew/opt/sqlite/lib -Wl,-rpath,/opt/homebrew/opt/mysql-client/lib ${LDFLAGS:-}"

PGROOT="$(brew --prefix libpq)"
SQLROOT="$(brew --prefix sqlite)"
MYROOT="$(brew --prefix mysql-client)"

# Sanity: should be arm64
echo "== Sanity: dylib architectures =="
file "$PGROOT/lib/libpq.dylib"
file "$SQLROOT/lib/libsqlite3.dylib"
file "$MYROOT/lib/libmysqlclient.dylib"
echo

# ===== Configure =====
echo "== Configuring CMake =="
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$POCO_SRC_DIR" -G "$GENERATOR" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
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

# ===== Build =====
echo "== Building =="
if [[ "$GENERATOR" == "Unix Makefiles" ]]; then
  make -j
else
  cmake --build . -j
fi

# ===== Install to system defaults (/usr/local) =====
echo "== Installing to /usr/local (sudo required) =="
if [[ "$GENERATOR" == "Unix Makefiles" ]]; then
  sudo make install
else
  sudo cmake --install .
fi

echo "✅ Done. POCO installed into /usr/local."
echo "   Verify with: otool -L /usr/local/lib/libPocoData{MySQL,PostgreSQL,SQLite}.dylib 2>/dev/null"