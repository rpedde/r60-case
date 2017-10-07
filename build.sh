#!/bin/bash

set -eux

if [ $# -eq 1 ]; then
    HEIGHT=$1
fi

function gen() {
    local what=$1
    local format=$2
    local varies=$3

    optargs=""
    optfname=""

    if [ "${HEIGHT:-}" != "" ]; then
        optargs="-D stock_height=$HEIGHT"
        if [ "${varies}" == "yes" ]; then
          optfname="-${HEIGHT}"
        fi
    fi

    openscad -o r60-${what}${optfname}.${format} -D "mod=\"${what}\"" ${optargs} r60.scad
}

for d in case:stl:yes holes:dxf:no usb:dxf:no standoff:stl:yes bottom:dxf:no feet:dxf:no clamps:stl:yes sidecut:dxf:no; do
    items=($(echo ${d} | tr ":" " "))

    what=${items[0]}
    format=${items[1]}
    varies_by_height=${items[2]}

    echo "Generating ${what} (format: ${format})"
    gen $what $format $varies_by_height
done
