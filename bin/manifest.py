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
 * sampleid - a string found in the fastq file name uniquely identifying a specimen
 * sample_name - a specimen label for display in outputs

Optional fields:
 * project - an identifier that can be used to group specimens in subsequent analyses
 * batch - an identifer used to group specimens into PCR batches for
   dada2 model generation
 * controls - a column that can be used to indicate which specimens
   are controls. Specimens matching --neg-control-pattern are defined
   as negative controls

TODO: validators for manifest
- make sure all samplids are unique


"""

import os
import sys
import argparse
import json
from itertools import takewhile
from operator import attrgetter
import csv

import openpyxl

KEEPCOLS = {'sampleid', 'sample_name', 'project', 'batch', 'controls'}


def read_manifest_excel(fname, keepcols=KEEPCOLS):
    """Read the first worksheet from an excel file and return a generator
    of dicts with keys limited to 'keepcols'.

    """

    valgetter = attrgetter('value')

    wb = openpyxl.load_workbook(fname)
    sheet = wb[wb.sheetnames[0]]

    rows = (r for r in sheet.iter_rows() if r[0].value)

    # get fieldnames from cells in the first row up to the first empty one
    header = takewhile(valgetter, next(rows))
    # replace column names to be discarded with '_'
    fieldnames = [(cell.value if cell.value in keepcols else '_') for cell in header]
    popextra = '_' in fieldnames

    for row in rows:
        d = dict(zip(fieldnames, map(valgetter, row)))
        if popextra:
            d.pop('_')
        yield d


def read_manifest_csv(fname, keepcols=KEEPCOLS):

    with open(fname) as f:
        reader = csv.DictReader(f)
        reader.fieldnames = [(n if n in keepcols else '_') for n in reader.fieldnames]
        popextra = '_' in reader.fieldnames
        for d in reader:
            if popextra:
                d.pop('_')
            yield dict(d)


def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('manifest', help="Manifest in excel or csv format")
    parser.add_argument('data_dir', help="Directory containing fastq.gz files")
    parser.add_argument('-o', '--outfile', help="Output .json file")

    args = parser.parse_args(arguments)
    read_manifest = (read_manifest_csv if args.manifest.endswith('.csv')
                     else read_manifest_excel)
    manifest = list(read_manifest(args.manifest))
    for d in manifest:
        print(d)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

