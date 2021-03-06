#!/usr/bin/env python3

"""Read cmalign alignment scores and indicate sequences with a score
above a specified bit score.

"""

import os
import sys
import argparse
import csv
from collections import defaultdict

from fastalite import fastalite

class DevNull:
    def write(*args, **kwargs):
        pass

    def writerow(*args, **kwargs):
        pass


def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('seqs', help="input sequences",
                        type=argparse.FileType('r'))
    parser.add_argument('cmscores', help="output of cmalign --sfile",
                        type=argparse.FileType('r'))
    parser.add_argument('--weights',
                        type=argparse.FileType('r'))
    # outputs
    parser.add_argument('--passing', help="output fasta of passing sequences",
                        type=argparse.FileType('w'))
    parser.add_argument('--failing', help="outpt fasta of failing sequences",
                        type=argparse.FileType('w'))
    parser.add_argument('--outcomes', help="output outcome for each sv",
                        type=argparse.FileType('w'))
    parser.add_argument('--counts', type=argparse.FileType('w'),
                        help=("output counts of '16s' and 'other' reads per specimen",
                              "(requires --weights)"))
    parser.add_argument('--min-bit-score', type=int, default=0,
                        help='minimum bit score [default %(default)s]')

    args = parser.parse_args(arguments)
    passing = args.passing or DevNull()
    failing = args.failing or DevNull()
    outcomes = csv.writer(args.outcomes) if args.outcomes else DevNull()

    colnames = ['idx', 'seq_name', 'length', 'cm_from', 'cm_to',
                'trunc', 'bit_sc', 'avg_pp', 'band_calc', 'alignment',
                'total', 'mem']
    name, score = colnames.index('seq_name'), colnames.index('bit_sc')
    lines = [line.split() for line in args.cmscores if not line.startswith('#')]
    is_16s = {line[name]: float(line[score]) > args.min_bit_score for line in lines}

    outcomes.writerow(['seqname', 'is_16s'])
    for seq in fastalite(args.seqs):
        output = '>{seq.id}\n{seq.seq}\n'.format(seq=seq)
        outcomes.writerow([seq.id, is_16s[seq.id]])
        if is_16s[seq.id]:
            passing.write(output)
        else:
            failing.write(output)

    if args.counts and args.weights:
        weights = csv.reader(args.weights)

        y, n = defaultdict(int), defaultdict(int)
        for rep, sv, count in weights:
            specimen = sv.split(':')[-1]
            if is_16s[rep]:
                y[specimen] += int(count)
            else:
                n[specimen] += int(count)

        writer = csv.writer(args.counts)
        writer.writerow(['sampleid', '16s', 'not_16s'])
        for specimen in sorted(set(y.keys()) | set(n.keys())):
            writer.writerow([specimen, y[specimen], n[specimen]])


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

