#!/usr/bin/env python

import argparse
import os
import subprocess
import sys

import jinja2

OUTPUT_VARS = {}

outputs = {
    'case': {
        'format': 'stl',
        'depends': ['stock', 'height', 'slop'],
    },
    'holes': {
        'format': 'dxf',
        'depends': ['slop']
    },
    'usb': {
        'format': 'dxf',
        'depends': ['height', 'slop']
    },
    'standoff': {
        'format': 'stl',
        'depends': ['stock', 'slop']
    },
    'bottom': {
        'format': 'dxf',
        'depends': ['slop']
    },
    'feet': {
        'format': 'dxf',
        'depends': ['slop']
    },
    'clamps': {
        'format': 'stl',
        'depends': ['stock']
    },
    'sidecut': {
        'format': 'dxf',
        'depends': []
    }
}

board_params = {
    'r60': {
        'board_width': 285.75,
        'board_height': 95.25,
        'holes': [
            [25.2, 66.7],
            [260.05, 66.7],
            [128.2, 47.5],
            [190.5, 9.4],
            [3, 38.1],
            [282, 38.1]],
        'usb_offset': 19.05,
        'sidecut_size': 25.4,
        'reset_center': [28.5, 47.625]
    },
    'r68': {
        'board_width': 304.80,
        'board_height': 95.25,
        'holes': [
            [25.575, 67.025],
            [25.575, 9.525],
            [128.575, 47.625],
            [190.5, 9.525],
            [260.425, 67.025],
            [266.70, 9.525]],
        'usb_offset': 18.4,
        'sidecut_size': 25.4,
        'reset_center': [28.5, 47.625]
    },
    'numpad': {
        'board_width': 76.2,
        'board_height': 95.25,
        'holes': [
            [19.05, 28.575],
            [47.625, 19.05],
            [19.05, 85.725],
            [57.15, 85.725]],
        'usb_offset': 38.10,
        'sidecut_size': 12.7,
        'reset_center': [38.1, 28.575]
    }
}


def get_rev():
    cmd = 'git rev-parse --short=6 HEAD'.split()

    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    returncode = p.poll()

    if returncode:
        print 'Error getting git version'
        print stderr

        return 'unknown'

    rev = stdout.split('\n')[0].strip()

    cmd = 'git diff-index --name-only HEAD --'.split()
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    returncode = p.poll()

    if returncode:
        print 'Error getting git version'
        print stderr

        return 'unknown'

    changed = stdout.strip().split('\n')
    if len(changed):
        rev += '+local'

    return rev


def template_file(infile, outfile, kwargs):
    path, filename = os.path.split(infile)
    j2_env = jinja2.Environment(loader=jinja2.FileSystemLoader(path) or '.')
    result = j2_env.get_template(filename).render(**kwargs)

    with open(outfile, 'w') as f:
        f.write(result)


def genscad(args):
    j2_kwargs = board_params[args.type]
    j2_kwargs['usb_offset'] += args.shift_usb
    j2_kwargs['args'] = vars(args)
    j2_kwargs['build_ver'] = get_rev()

    outfile = args.outfile
    if not outfile:
        outfile = '%s.scad' % args.type

    template_file('case.scad.j2', outfile, j2_kwargs)

    return outfile


def get_parser():
    parser = argparse.ArgumentParser(description='Generate case artifacts')

    parser.add_argument('type', help='case type',
                        default='r60',
                        choices=['r60', 'r68', 'numpad'])

    parser.add_argument('--scad-only', help='do not generate output files',
                        action='store_true')
    parser.add_argument('--stock', help='stock height',
                        type=float, default=25.4)
    parser.add_argument('--height', help='height over standoffs',
                        type=float, default=11.0)
    parser.add_argument('--slop', help='extra slop in the inside of case',
                        type=float, default=1.5)
    parser.add_argument('--shift-usb', help='how far to move usb (-1 for r60)',
                        type=float, default=0.0)
    parser.add_argument('--top', help='whether to generate interlocked top',
                        action='store_true')

    parser.add_argument('--outfile', help='ouput scad file')

    return parser


def build_output(fname, args, output, format=None, depends=None):
    global OUTPUT_VARS

    if format is None:
        format = 'stl'

    if depends is None:
        depends = []

    dest_fname = args.type + '-' + output
    for item in sorted(depends):
        value = getattr(args, item)
        dest_fname += '-%s=%s' % (item, value)

    dest_fname += '.%s' % format

    cmd = ('openscad %s -o %s -D mod="%s"' % (
        fname, dest_fname, output)).split()

    print 'Building %s' % dest_fname

    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    returncode = p.poll()

    for line in stderr.split('\n'):
        line = line.strip()
        if line.startswith("ECHO:"):
            res = line[7:-1]
            if res.startswith('H:'):
                _, key, value = res.split(':')
                OUTPUT_VARS[key.strip()] = value.strip()

    OUTPUT_VARS['version'] = get_rev()

    if returncode:
        sys.stderr.write('Error executing "%s"\n' % (' '.join(cmd)))
        sys.stderr.write(stderr)

        sys.exit(1)


def main(rawargs):
    args = get_parser().parse_args(rawargs)

    args.cli = sys.argv

    fname = genscad(args)

    if not args.scad_only:
        for output, values in outputs.iteritems():
            build_output(fname, args, output, **values)

        if OUTPUT_VARS:
            with open('%s-vars.txt' % args.type, 'w') as f:
                for k in sorted(OUTPUT_VARS.keys()):
                    v = OUTPUT_VARS[k]
                    f.write('%s = %s\r\n' % (k, v))

if __name__ == '__main__':
    main(sys.argv[1:])
