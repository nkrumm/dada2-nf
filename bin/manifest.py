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
 * sampleid - a string found in the fastq file name uniquely identifying a
   specimen
 * sample_name - a specimen label for display in outputs

Optional fields:
 * project - an identifier that can be used to group specimens in subsequent
   analyses
 * batch - an identifer used to group specimens into PCR batches for
   dada2 model generation
 * controls - a column that can be used to indicate which specimens
   are controls. Specimens matching --neg-control-pattern are defined
   as negative controls

TODO: validators for manifest
- make sure all samplids are unique
"""
import argparse
import csv
import glob
import itertools
import openpyxl
import operator
import os
import sys


KEEPCOLS = {'sampleid', 'sample_name', 'project', 'batch', 'controls'}


def read_manifest_excel(fname, keepcols=KEEPCOLS):
    """Read the first worksheet from an excel file and return a generator
    of dicts with keys limited to 'keepcols'.

    """

    valgetter = operator.attrgetter('value')

    wb = openpyxl.load_workbook(fname)
    sheet = wb[wb.sheetnames[0]]

    rows = (r for r in sheet.iter_rows() if r[0].value)

    # get fieldnames from cells in the first row up to the first empty one
    header = itertools.takewhile(valgetter, next(rows))
    # replace column names to be discarded with '_'
    fieldnames = [(cell.value if cell.value in keepcols else '_')
                  for cell in header]
    popextra = '_' in fieldnames

    for row in rows:
        d = dict(zip(fieldnames, map(valgetter, row)))
        if popextra:
            d.pop('_')
        yield d


def read_manifest_csv(fname, keepcols=KEEPCOLS):

    with open(fname) as f:
        reader = csv.DictReader(f)
        reader.fieldnames = [(n if n in keepcols else '_')
                             for n in reader.fieldnames]
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
    parser.add_argument('-o', '--outfile', help="Output .json file",
                        type=argparse.FileType('w'), default=sys.stdout)
    args = parser.parse_args(arguments)
    if args.manifest.endswith('.csv'):
        read_manifest = read_manifest_csv
    else:
        read_manifest = read_manifest_excel
    manifest = list(read_manifest(args.manifest))
    sampledata = {d['sampleid']: d for d in manifest}
    # make sure all sampleids are unique
    assert len(manifest) == len(sampledata)
    index_reads = []
    sample_reads = []
    for fastq in glob.glob(os.path.join(args.data_dir, '*.fastq.gz')):
        sample_details = os.path.basename(fastq).split('_')
        sampleid = sample_details[0]
        sample_type = sample_details[3]
        if sampleid in sampledata:
            if sample_type in ['I1', 'I2']:
                decorated = index_reads
            else:
                decorated = sample_reads
            decorated.append({
                'batch': sampledata[sampleid]['batch'],
                'path': fastq,
                'sampleid': sampleid,
                'sample_type': sample_type
            })
    key = operator.itemgetter('sampleid', 'sample_type')
    index_reads = sorted(index_reads, key=key)
    key = operator.itemgetter('sampleid')
    index_reads_dict = {}
    for sampleid, group in itertools.groupby(index_reads, key=key):
        index_reads_dict[sampleid] = list(group)
    outfile = csv.DictWriter(
        args.outfile,
        fieldnames=['sampleid', 'batch', 'sample_type', 'I1', 'I2', 'reads'],
        extrasaction='ignore')
    outfile.writeheader()
    for r in sample_reads:
        i1, i2 = index_reads_dict[r['sampleid']]
        r.update({'I1': i1['path'], 'I2': i2['path'], 'reads': r['path']})
        outfile.writerow(r)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
