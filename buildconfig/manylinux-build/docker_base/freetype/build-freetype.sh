#!/bin/bash
set -e -x

cd $(dirname `readlink -f "$0"`)

FREETYPE="freetype-2.14.1"
HARFBUZZ_VER=12.1.0
HARFBUZZ_NAME="harfbuzz-$HARFBUZZ_VER"

# 使用 SourceForge 镜像替代 Savannah
curl -fsSL --retry 10 --retry-delay 5 \
  "https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE#freetype-}/${FREETYPE}.tar.gz" \
  -o "${FREETYPE}.tar.gz"

curl -fsSL --retry 10 --retry-delay 5 \
  "https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VER}/${HARFBUZZ_NAME}.tar.xz" \
  -o "${HARFBUZZ_NAME}.tar.xz"

# 验证文件完整性
file "${FREETYPE}.tar.gz"
file "${HARFBUZZ_NAME}.tar.xz"

# extract installed sources
tar xzf ${FREETYPE}.tar.gz
unxz ${HARFBUZZ_NAME}.tar.xz
tar xf ${HARFBUZZ_NAME}.tar

cd $FREETYPE

# For now bzip2 is only used on macOS, on other platforms there are issues with
# it.
if [[ "$OSTYPE" == "darwin"* ]]; then
    export PG_FT_BZ2="-Dbzip2=enabled"
else
    export PG_FT_BZ2="-Dbzip2=disabled"
fi

meson setup _build $PG_BASE_MESON_FLAGS -Dbrotli=enabled -Dharfbuzz=dynamic \
    -Dpng=enabled -Dzlib=system $PG_FT_BZ2

meson compile -C _build
meson install -C _build

cd ..

cd ${HARFBUZZ_NAME}

# harfbuzz has a load of optional dependencies but only freetype is important
# to us.
# Cairo and chafa are only needed for harfbuzz commandline utilities so we
# don't use it. glib available is a bit old so we don't prefer it as of now.
# we also don't compile-in icu so that harfbuzz uses built-in unicode handling
meson setup _build $PG_BASE_MESON_FLAGS -Dfreetype=enabled \
    -Dglib=disabled -Dgobject=disabled -Dcairo=disabled -Dchafa=disabled -Dicu=disabled \
    -Dtests=disabled -Dintrospection=disabled -Ddocs=disabled

meson compile -C _build
meson install -C _build

cd ..
