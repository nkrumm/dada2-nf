fastq = Channel.fromPath("test/fastq/*").collect()
sample_info = Channel.fromPath("test/sample-information.csv")

process create_manifest {

    // container null

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

// TODO: allow barcodecop to handle empty input and output data
process barcodecop {
    input:
    tuple sampleid, batch, sample_type, I1, I2, R from manifest.splitCsv(header: true)
    file("test/fastq/") from fastq

    output:
    tuple batch, file("${sampleid}_${sample_type}_counts.csv") into barcode_counts
    file("${sampleid}_${sample_type}_.fq.gz") into to_filt_trim
    file("${sampleid}_${sample_type}_.fq.gz") into to_plot

    publishDir "${params.output}/batch_${batch}/fq/", overwrite: true

    """
    barcodecop --fastq ${R} \
    	       --match-filter \
	       --outfile ${sampleid}_${sample_type}_.fq.gz \
	       --read-counts ${sampleid}_${sample_type}_counts.csv \
	       --quiet ${I1} ${I2}
    """
}

process sample_counts {

    input:
    tuple batch, file("*_counts.csv") from barcode_counts.groupTuple()

    output:
    tuple batch, file("counts.csv") into counts

    publishDir "${params.output}/batch_${batch}/", overwrite: true

    """
    cat *_counts.csv > counts.csv
    """
}

process fastq_list {

    input:
    tuple batch, file("counts.csv") from counts.groupTuple()

    output:
    tuple batch, file("fastq_list.txt") into batch_list
    file("fastq_list.txt") into fastq_list
    file("samples.csv") into sample_list

    publishDir "${params.output}/batch_${batch}/", overwrite: true

    """
    fastq_list.py \
	counts.csv ${batch} \
	--min-reads 1 \
	--outfile fastq_list.txt \
	--sample-list samples.csv
    """
}

// process plot_quality {

//     input:
//     tuple batch, sampleid, fwd, rev from sample_list.splitCsv(header: true)
//     file("") from to_plot.collect()

//     output:
//     file("qplot_${sampleid}.svg")

//     publishDir "${params.output}/batch_${batch}/qplots/", overwrite: true

//     """
//     dada2_plot_quality.R ${fwd} ${rev} --f-trunc 280 -o qplot_${sampleid}.svg --r-trunc 250 --title \"${sampleid} (batch ${batch})\" --trim-left 15
//     """
// }

// TODO: consider handling empty fastqs in dada2_filter_and_trim.R
process filter_and_trim {

    input:
    tuple batch, file("fastq_list.txt") from batch_list.filter{r -> !file(r[1]).isEmpty()}
    file("") from to_filt_trim.collect()

    output:
    tuple batch, file("*_filt.fastq.gz") into filtered

    publishDir "${params.output}/batch_${batch}/filtered/", overwrite: true

    """
    dada2_filter_and_trim.R fastq_list.txt \
	--filt-path . \
	--trim-left 15 \
	--f-trunc 280 \
	--r-trunc 250 \
	--truncq 2
    """
}

// clone channel so that it can be consumed twice
filtered.into { filtered_learn_errors; filtered_dada }

process learn_errors {

    input:
    tuple batch, file("") from filtered_learn_errors

    output:
    tuple batch, file("error_model.rds") into error_model
    file("error_model.png") into error_model_plots

    publishDir "${params.output}/batch_${batch}/", overwrite: true

    """
    dada2_learn_errors.R . --model error_model.rds --plots error_model.png --nthreads 10
    """
}

// prepare input for dada_dereplicate
// returns channel of [batch, model, sampleid, R1, R2]
// https://www.nextflow.io/docs/latest/operator.html
error_model
    .join(filtered_dada)
    .map { x -> [x[0], x[1], x[2].collate(2)] }
    .transpose()
    .map { y -> y.flatten() }
    .map { z -> [z[0], z[1], file(z[2]).baseName.replaceFirst(/_R1_filt.*/, ""), z[2], z[3]] }
    .set { dada_input }

process dada_dereplicate {

    input:
	tuple batch, file("model.rds"), sampleid, \
    file("R1.fastq.gz"), file("R2.fastq.gz") from dada_input

    output:
	file("dada.rds") into dada_data
    file("seqtab.csv") into dada_seqtab
    file("counts.csv") into dada_counts
    file("overlaps.csv") into dada_overlaps

    publishDir "${params.output}/${sampleid}/", overwrite: true

    // TODO: set --self-consist to TRUE in production

    """
    dada2_dada.R R1.fastq.gz R2.fastq.gz --errors model.rds \
	--sampleid ${sampleid} \
	--self-consist FALSE \
	--data dada.rds \
	--seqtab seqtab.csv \
	--counts counts.csv \
	--overlaps overlaps.csv
    """
}

process combined_overlaps {

    input:
    file("overlaps_*.csv") from dada_overlaps.collect()

    output:
    file("overlaps.csv")

    publishDir params.output, overwrite: true

    """
    csvcat.sh overlaps_*.csv > overlaps.csv
    """
}

process write_seqs {

    input:
    file("seqtab_*.csv") from dada_seqtab.collect()

    output:
    file("seqs.fasta") into seqs
    file("specimen_map.csv")
    file("dada2_sv_table.csv")
    file("dada2_sv_table_long.csv")
    file("weights.csv")

    publishDir params.output, overwrite: true

    """
    write_seqs.py seqtab_*.csv \
	--seqs seqs.fasta \
	--specimen-map specimen_map.csv \
	--sv-table dada2_sv_table.csv \
	--sv-table-long dada2_sv_table_long.csv \
	--weights weights.csv
    """
}

// clone channel so that it can be consumed twice
seqs.into { seqs_to_align; seqs_to_filter }

process cmalign {

    input:
    file("seqs.fasta") from seqs_to_align
    file('ssu-align-0.1.1-bacteria-0p1.cm') from file("data/ssu-align-0.1.1-bacteria-0p1.cm")

    output:
    file("seqs.sto")
    file("sv_aln_scores.txt") into aln_scores

    publishDir params.output, overwrite: true

    """
    cmalign \
	--cpu 10 --dnaout --noprob \
	-o seqs.sto \
	--sfile sv_aln_scores.txt ssu-align-0.1.1-bacteria-0p1.cm seqs.fasta
    """
}

process filter_16s {

    input:
	file("seqs.fasta") from seqs_to_filter
    file("sv_aln_scores.txt") from aln_scores

    output:
	file("16s.fasta")
        file("not16s.fasta")

    publishDir params.output, overwrite: true

    """
    filter_16s.py seqs.fasta sv_aln_scores.txt \
	--min-bit-score 0 \
	--passing 16s.fasta \
	--failing not16s.fasta
    """
}
