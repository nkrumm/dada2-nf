#!/usr/bin/env python3

"""Create a complete manifest of files for the data2-nf
pipeline. Inputs are a manifest and a directory containing fastq read
pairs. Output is a json-format file serializing an array of dicts
representing each specimen.

The objective of this approach is to consolidate all of the
file-naming and corresponding string processing and path manipulation
into a single location for the pipeline. Parameters for each specimen
are also specified here.

Required fields for the manifest:
 * ...
"""

import os
import sys
import argparse
import json


def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('manifest', help="Manifest in excel or csv format")
    # parser.add_argument('fastq_files', help="File ")
    parser.add_argument('-o', '--outfile', help="Output .json file")

    args = parser.parse_args(arguments)

    print(args)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

