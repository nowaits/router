#! /bin/sh
set -e

ROOT_DIR=${0%/*}

PY_SITE_PKGS=$1

if [ ! -d $PY_SITE_PKGS ]; then
    echo "python extesion dir: $PY_SITE_PKGS not exist!" 
    exit 1
fi

for file in $ROOT_DIR/*.*
do
    ext=${file##*.}
    if [ "$ext" == "egg" ]; then
        new_file=${file%.egg}.egg-info
        base_name=${new_file##*/}
        
        echo "$file => $PY_SITE_PKGS/$base_name"
        [ ! -d $PY_SITE_PKGS/$base_name ] || continue
        unzip -o $file -d $PY_SITE_PKGS
        mv $PY_SITE_PKGS/EGG-INFO $PY_SITE_PKGS/$base_name
    elif [ "$ext" == "whl" ]; then
        new_file=${file%.whl}
        base_name=${new_file##*/}
        echo "$file => $PY_SITE_PKGS/$base_name"
        unzip -o $file -d $PY_SITE_PKGS
    fi
done