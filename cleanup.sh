#!/bin/bash

AUR_DIR=$(dirname $0)

set -e
set -u

# Get a list of directories (ie, packages) in this directory
cd "$AUR_DIR"
PKGS=$(find ./ -type f -name PKGBUILD)

echo "Removing all src/ and pkg/ trees"
rm -Rf */{pkg,src}/

source /etc/makepkg.conf

# Loop through each package
for PKG in $PKGS ; do
  PKG=${PKG%/PKGBUILD}  # Strip the trailing "/PKGBUILD" string
  PKG=${PKG##*/}      # Strip the leading path "...../"
  echo "Cleaning up $PKG"

  #echo "   Inspecting with namcap..."
  namcap --exclude=fileownership,tags "$AUR_DIR/$PKG/PKGBUILD"

  #echo -n "   Removing build files... "
  rm -Rf "$AUR_DIR/$PKG/pkg"
  if [ ${PKG:(-4)} != "-svn" ] ; then
    rm -Rf "$AUR_DIR/$PKG/src"
  fi
  source "$AUR_DIR/$PKG/PKGBUILD"
  for SRC in ${source[@]} ; do
    IS_URL=$(echo $SRC | grep -E '(http|ftp)://' || true)
    FNAME=$(basename $SRC)
    if [ ! -z $IS_URL ] && [ -e "$AUR_DIR/$PKG/$FNAME" ] ; then
      rm "$AUR_DIR/$PKG/$FNAME"
    fi
  done
  #echo "Done"

  BUILT=$(find "$AUR_DIR/$PKG" -maxdepth 1 -name \*.pkg.tar.gz -o -name \*.src.tar.gz -print)
  if [ ! -z "$BUILT" ] ; then
    echo -n "   Moving built packages to $PKG/built... "
    [[ ! -d "$AUR_DIR/$PKG/built" ]] && mkdir "$AUR_DIR/$PKG/built"
    for fname in $BUILT ; do
      mv "$fname" "$AUR_DIR/$PKG/built/"
    done
    echo "Done"
  fi

  #echo -n "   Fixing permissions... "
  chmod 640 "$AUR_DIR/$PKG/PKGBUILD"
  chmod 750 "$AUR_DIR/$PKG"
  #echo "Done"
done

exit 0
