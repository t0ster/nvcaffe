#!/bin/bash
# example usage: change_mofed_version.sh 4.5-1.0.1

MOFED_VERSION="$1"

DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/DEBS"

if [[ -z "$MOFED_VERSION" ]]; then
  echo "Usage example: change_mofed_version.sh 4.5-1.0.1" >&2
  exit 1
fi
if [[ ! -d "${DIR}/${MOFED_VERSION}" ]]; then
  echo "MOFED version '$MOFED_VERSION' not available in this container." >&2
  MOFED_VERSION=$(echo "${MOFED_VERSION}" | cut -d- -f1)
  if ls -d ${DIR}/${MOFED_VERSION}-* >&/dev/null; then
    MOFED_VERSION=$(cd ${DIR} ; ls -d ${MOFED_VERSION}-* | sort -n | tail -n1)
    echo "Selected ${MOFED_VERSION} as an alternative." >&2
  else
    echo "No matching alternate version found." >&2
    exit 1
  fi
fi

MOFED_DIR=$(mktemp -d)
pushd ${MOFED_DIR} >/dev/null

for i in ${DIR}/${MOFED_VERSION}/*.deb; do
  ar x $i
  tar xf data.tar.xz
  rm control.tar.* data.tar.xz debian-binary
done

( 
cp usr/bin/ibv_* /usr/bin/
[ -f usr/lib/libmlx5.so.1.0.0 ] && cp usr/lib/libmlx5.so.1.0.0 /usr/lib/
cp -R usr/lib/libibverbs/* /usr/lib/libibverbs/
cp usr/lib/libibverbs.* /usr/lib/
rm -f /usr/lib/libibverbs.so /usr/lib/libibverbs.a
) 2>/dev/null

popd >/dev/null
echo "$MOFED_DIR" # used by /.singularity.d/env/25-mellanox-ibv-compat.sh; this should be the only stdout
