sample_info = Channel.fromPath( 'test/sample-information.csv' )
fastq = Channel.fromPath( 'test/fastq/*' ).collect()

// TODO: READ counts here
// TODO: output to csv??
process create_manifest {
  // container "python:3.6.7-stretch"  Needs openpyxl
  input:
  file("test/sample-information.csv") from sample_info
  file("test/fastq/") from fastq

  output:
  file("manifest.csv") into manifest

  publishDir params.output, copy: true, overwrite: true

  """
  manifest.py --outfile manifest.csv test/sample-information.csv test/fastq/
  """
}

// TODO: allow barcodecop to work with empty data
process run_barcodecop {
    container "barcodecop:latest"

    input:
    set sampleid, batch, I1, I2, R1, R2 from manifest.splitCsv(header: true)
    file("test/fastq/") from fastq

    output:
    set sampleid, batch, file("${sampleid}_R1.fq.gz"), file("${sampleid}_R2.fq.gz") into barcodecop
    set val("${sampleid}_R1.fq.gz"), val("${sampleid}_R2.fq.gz") into pairs
    set file("${sampleid}_R1.fq.gz"), file("${sampleid}_R2.fq.gz") into to_filt_trim
    file("${sampleid}_R1_counts.csv")
    file("${sampleid}_R2_counts.csv")

    publishDir params.output, copy: true, overwrite: true

    """
    barcodecop --csv-counts ${sampleid}_R1_counts.csv --fastq ${R1} --match-filter --quiet ${I1} ${I2} | gzip > ${sampleid}_R1.fq.gz
    barcodecop --csv-counts ${sampleid}_R2_counts.csv --fastq ${R2} --match-filter --quiet ${I1} ${I2} | gzip > ${sampleid}_R2.fq.gz
    """
}

process plot_quality {
    container "nghoffman/dada2:release-1.8.0"

    input:
    set sampleid, batch, file("fwd.fq.gz"), file("rev.fq.gz") from barcodecop

    output:
    file("qplot_${sampleid}.svg")

    publishDir params.output, copy: true, overwrite: true

    """
    dada2_plot_quality.R fwd.fq.gz rev.fq.gz --f-trunc 280 -o qplot_${sampleid}.svg --r-trunc 250 --title \"${sampleid} (batch ${batch})\" --trim-left 15
    """
}

// Channel.toPath - https://github.com/nextflow-io/nextflow/issues/774
process list_files {
    container "ubuntu:18.04"

    input:
    val(p) from pairs.collect()

    output:
    file("fastq_list.txt") into fastq_list

    publishDir params.output, copy: true, overwrite: true

    """
    echo \"${p.join('\n')}\" > fastq_list.txt
    """
}

process filter_and_trim {
    container "nghoffman/dada2:release-1.8.0"

    input:
    file(f) from to_filt_trim.collect()
    file("fastq_list.txt") from fastq_list

    output:
    file("*_filt.fastq.gz") into filtered

    """
    dada2_filter_and_trim.R fastq_list.txt --trim-left 15 --f-trunc 280 --r-trunc 250 --truncq 2 --filt-path .
    """
}


