fastq = Channel.fromPath("test/fastq/*").collect()
sample_info = Channel.fromPath("test/sample-information.csv")

// TODO: READ counts here
// TODO: output to csv??
process create_manifest {
  input:
  file("test/sample-information.csv") from sample_info
  file("test/fastq/") from fastq

  output:
  file("manifest.csv") into manifest

  publishDir params.output, overwrite: true

  """
  manifest.py --outfile manifest.csv test/sample-information.csv test/fastq/
  """
}

// TODO: allow barcodecop to work with empty data
process run_barcodecop {
    input:
    set sampleid, batch, I1, I2, R1, R2 from manifest.splitCsv(header: true)
    file("test/fastq/") from fastq

    output:
    set batch, sampleid, file("${sampleid}_R1_.fq.gz"), file("${sampleid}_R2_.fq.gz") into barcodecop
    set batch, val("${sampleid}_R1_.fq.gz"), val("${sampleid}_R2_.fq.gz") into pairs
    set file("${sampleid}_R1_.fq.gz"), file("${sampleid}_R2_.fq.gz") into to_filt_trim

    publishDir "${params.output}/batch_${batch}/fq/", overwrite: true

    """
    barcodecop --fastq ${R1} --match-filter --quiet ${I1} ${I2} | gzip > ${sampleid}_R1_.fq.gz
    barcodecop --fastq ${R2} --match-filter --quiet ${I1} ${I2} | gzip > ${sampleid}_R2_.fq.gz
    """
}

process plot_quality {
    input:
    set batch, sampleid, file("fwd.fq.gz"), file("rev.fq.gz") from barcodecop

    output:
    file("qplot_${sampleid}.svg")

    publishDir "${params.output}/batch_${batch}/qplots/", overwrite: true

    """
    dada2_plot_quality.R fwd.fq.gz rev.fq.gz --f-trunc 280 -o qplot_${sampleid}.svg --r-trunc 250 --title \"${sampleid} (batch ${batch})\" --trim-left 15
    """
}

// Channel.toPath - https://github.com/nextflow-io/nextflow/issues/774
process list_files {
    input:
    set batch, val(r1), val(r2) from pairs.groupTuple()

    output:
    set batch, file("fastq_list.txt") into batch_list
    file("fastq_list.txt") into fastq_list

    publishDir "${params.output}/batch_${batch}/", overwrite: true

    """
    echo \"${r1.join('\n')}\n${r2.join('\n')} \" > fastq_list.txt
    """
}

process filter_and_trim {
    input:
    set batch, file("fastq_list.txt") from batch_list
    file("") from to_filt_trim.collect()

    output:
    set batch, file("*_filt.fastq.gz") into filtered

    publishDir "${params.output}/batch_${batch}/filtered/", overwrite: true

    """
    dada2_filter_and_trim.R fastq_list.txt --trim-left 15 --f-trunc 280 --r-trunc 250 --truncq 2 --filt-path .
    """
}

process dereplicate {
    input:
    set batch, file("") from filtered

    output:
    set batch, file("dada2.rda") into rda
    file("seqtab_nochim.rda") into seqtab_nochim

    publishDir "${params.output}/batch_${batch}/", overwrite: true

    """
    dada2_dereplicate.R . --rdata dada2.rda --seqtab-nochim seqtab_nochim.rda --max-mismatch 1
    """
}

process overlaps {
    input:
    set batch, file("dada2.rda") from rda

    output:
    file("overlaps.csv") into overlaps

    publishDir "${params.output}/batch_${batch}/", overwrite: true

    """
    dada2_overlaps.R dada2.rda --batch ${batch} -o overlaps.csv
    """
}

process list_all_files {
    input:
    file("fastq_list_*.txt") from fastq_list.collect()

    output:
    file("fastq_list.txt")

    publishDir params.output, overwrite: true

    """
    cat fastq_list_*.txt > fastq_list.txt
    """
}

process combined_overlaps {
    input:
    file("overlaps_*.csv") from overlaps.collect()

    output:
    file("overlaps.csv")

    publishDir params.output, overwrite: true

    """
    csvcat.sh overlaps_*.csv > overlaps.csv
    """
}

process write_seqs {
    input:
    file("seqtab_nochim_*.rda") from seqtab_nochim.collect()

    output:
    file("seqs.fasta") into seqs
    file("specimen_map.csv")
    file("dada2_sv_table.csv")
    file("dada2_sv_table_long.csv")
    file("weights.csv")

    publishDir params.output, overwrite: true

    """
    dada2_write_seqs.R seqtab_nochim_*.rda --seqs seqs.fasta --specimen-map specimen_map.csv --sv-table dada2_sv_table.csv --sv-table-long dada2_sv_table_long.csv --weights weights.csv
    """
}

process cmalign {
    input:
    file("seqs.fasta") from seqs
    set cm from file("data/ssu-align-0.1.1-bacteria-0p1.cm")

    output:
    file("seqs.sto")
    file("sv_aln_scores.txt") into seqs_scores

    publishDir params.output, overwrite: true

    """
    cmalign --cpu 10 --dnaout --noprob -o seqs.sto --sfile sv_aln_scores.txt ${cm} seqs.fasta
    """
}

process not_16s {
    input:
    file("sv_aln_scores.txt") from seqs_scores

    output:
    file("not_16s.txt")

    publishDir params.output, overwrite: true

    """
    read_cmscores.py --min-bit-score 0 -o not_16s.txt sv_aln_scores.txt
    """
}
