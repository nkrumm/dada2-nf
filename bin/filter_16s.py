#!/usr/bin/env python3

"""Read cmalign alignment scores and provide a list of sequences with
a score below some threshold.

"""

from __future__ import print_function
import os
import sys
import argparse

from fastalite import fastalite


def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('seqs', help="input sequences",
                        type=argparse.FileType('r'))
    parser.add_argument('cmscores', help="output of cmalign --sfile",
                        type=argparse.FileType('r'))
    parser.add_argument('--passing', help="fasta of passing sequences",
                        type=argparse.FileType('w'))
    parser.add_argument('--failing', help="fasta of failing sequences",
                        type=argparse.FileType('w'))
    parser.add_argument('--min-bit-score', type=int, default=0,
                        help='minimum bit score [default %(default)s]')

    args = parser.parse_args(arguments)

    colnames = ['idx', 'seq_name', 'length', 'cm_from', 'cm_to',
                'trunc', 'bit_sc', 'avg_pp', 'band_calc', 'alignment',
                'total', 'mem']

    seqdict = {seq.id: seq for seq in fastalite(args.seqs)}

    lines = [dict(zip(colnames, line.split()))
             for line in args.cmscores if not line.startswith('#')]

    for line in lines:
        seq = seqdict[line['seq_name']]
        output = '>{seq.id}\n{seq.seq}\n'.format(seq=seq)
        if float(line['bit_sc']) > args.min_bit_score:
            args.passing.write(output)
        else:
            args.fail.write(output)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

