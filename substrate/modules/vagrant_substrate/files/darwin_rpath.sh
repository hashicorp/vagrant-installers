#!/usr/bin/env bash

set -ex

function relpath() {
    path_to="${2}"
    source="${1}"
    rel=$(perl -MFile::Spec -e "print File::Spec->abs2rel(q($path_to),q($source))")
    echo $rel
}

# Location of our embedded directory
embedded_dir=$1

for lib_path in $(find "${embedded_dir}" -name "*.dylib"); do
    lib_name=$(basename "${lib_path}")
    install_name_tool -id "@rpath/${lib_name}" "${lib_path}"

    for scrub_name in $(otool -l "${lib_path}" | grep "^ *name" | awk '{print $2}'); do
        set +e
        echo "${scrub_name}" | grep "${embedded_dir}"
        if [ $? -eq 0 ]; then
            set -e
            lib_name=$(basename "${scrub_name}")
            install_name_tool -change "${scrub_name}" "@rpath/${lib_name}" "${lib_path}"
        fi
        set -e
    done

    for scrub_path in $(otool -l "${lib_path}" | grep "^ *path" | awk '{print $2}'); do
        install_name_tool -delete_rpath "${scrub_path}" "${lib_path}"
    done
done

for exe_path in $(find "${embedded_dir}" -type f -perm +111); do
    set +e
    otool -l "${exe_path}" | grep "not an object"
    if [ $? -ne 0 ]; then
        exe_dir=$(dirname "${exe_path}")
        rel_embedded=$(relpath "${exe_dir}" "${embedded_dir}")
        lib_embedded="${embedded_dir}/lib"
        rpath="@executable_path/${rel_embedded}/lib"

        echo "${exe_path}" | grep ".bundle$"
        if [ $? -ne 0 ]; then
            otool -l "${exe_path}" | grep "^ *path" | grep "${rpath}"
            if [ $? -ne 0 ]; then
                set -e
                install_name_tool -add_rpath "${rpath}" "${exe_path}"
            fi
        fi
        for scrub_name in $(otool -l "${exe_path}" | grep "^ *name" | awk '{print $2}'); do
            set +e
            echo "${scrub_name}" | grep "${embedded_dir}"
            if [ $? -eq 0 ]; then
                set -e
                lib_name=$(basename "${scrub_name}")
                install_name_tool -change "${scrub_name}" "@rpath/${lib_name}" "${exe_path}"
            fi
        done

        set -e

        for scrub_path in $(otool -l "${exe_path}" | grep "^ *path" | awk '{print $2}'); do
            if [ "${rpath}" -ne "${scrub_path}" ]; then
                install_name_tool -rpath "${scrub_path}" "${exe_path}"
            fi
        done
    fi
done
