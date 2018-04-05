#!/usr/bin/env bash

set -x

function relpath() {
    path_to=`readlink -f "$2"`
    source=`readlink -f "$1"`
    rel=$(perl -MFile::Spec -e "print File::Spec->abs2rel(q($path_to),q($source))")
    echo $rel
}

# Location of our embedded directory
embedded_dir=$1

for so_path in $(find "${embedded_dir}" -name "*.so"); do
    chrpath --list "${so_path}"
    if [ $? -eq 0 ]; then
        set -e
        so_dir=$(dirname "${so_path}")
        rel_embedded=$(relpath "${so_dir}" "${embedded_dir}")
        rpath="\$ORIGIN/${rel_embedded}/lib:\$ORIGIN/${rel_embedded}/lib64"
        chrpath --replace "${rpath}" "${so_path}"
        set +e
    fi
done

for exe_path in $(find "${embedded_dir}" -executable -type f); do
    file "${exe_path}" | grep "ELF"
    if [ $? -eq 0 ]; then
        chrpath --list "${exe_path}"
        if [ $? -eq 0 ]; then
            set -e
            exe_dir=$(dirname "${exe_path}")
            rel_embedded=$(relpath "${exe_dir}" "${embedded_dir}")
            rpath="\$ORIGIN/${rel_embedded}/lib:\$ORIGIN/${rel_embedded}/lib64"
            chrpath --replace "${rpath}" "${exe_path}"
            set +e
        fi
    else
        patchelf --set-rpath "${rpath}" "${exe_path}"
    fi
done

echo "complete."
