#!/usr/bin/env python3
"""
"""
import argparse
import csv
import itertools
import operator
import os
import sys


def main(arguments):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('sample_counts',
                        help="headerless sample counts in csv format",
                        type=argparse.FileType('r'))
    parser.add_argument('batch', help='batch label')
    parser.add_argument('--min-reads', default=0,
                        help='minimum read count', type=int)
    parser.add_argument('--sample-list',
                        help='csv file with headers batch,sampleid,R1,R2',
                        type=argparse.FileType('w'))
    parser.add_argument('-o', '--outfile',
                        default=sys.stdout, help="Filtered manifest file",
                        type=argparse.FileType('w'))

    args = parser.parse_args(arguments)

    counts = csv.DictReader(
        args.sample_counts, fieldnames=['path', 'input_count', 'output_count'])
    counts = (c for c in counts if int(c['output_count']) >= args.min_reads)
    samples = sorted(c['path'] for c in counts)  # must be sorted for Rscripts

    for s in samples:
        args.outfile.write(s + '\n')

    sample_list = []
    if args.sample_list:
        for path in samples:
            sample_details = os.path.basename(path).split('_')
            sampleid = sample_details[0]
            sample_type = sample_details[1]
            sample_list.append({
                'batch': args.batch,
                'path': path,
                'sampleid': sampleid,
                'sample_type': sample_type,
                })

        key = operator.itemgetter('sampleid', 'sample_type')
        sample_list = sorted(sample_list, key=key)
        fieldnames = ['batch', 'sampleid', 'R1', 'R2']
        outfile = csv.DictWriter(args.sample_list, fieldnames=fieldnames)
        outfile.writeheader()
        key = operator.itemgetter('sampleid')
        for i, group in itertools.groupby(sample_list, key=key):
            group = list(group)
            assert(len(group) == 2)  # R1, R2
            outfile.writerow({
                'batch': args.batch,
                'sampleid': i,
                'R1': group[0]['path'],
                'R2': group[1]['path']
                })


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
