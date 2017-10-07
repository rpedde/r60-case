#!/bin/bash

set -eux

if [ $# -eq 1 ]; then
    HEIGHT=$1
fi

function gen() {
    local what=$1
    local format=$2

    optargs=""
    optfname=""

    if [ "${HEIGHT:-}" != "" ]; then
        optargs="-D stock_height=$HEIGHT"
        optfname="-${HEIGHT}"
    fi

    openscad -o r60-${what}${optfname}.${format} -D "mod=\"${what}\"" ${optargs} r60.scad
}

for d in case:stl holes:dxf usb:dxf standoff:stl bottom:dxf feet:dxf clamps:stl sidecut:dxf; do
    what=${d%:*}
    format=${d#*:}

    echo "Generating ${what} (format: ${format})"
    gen $what $format
done
