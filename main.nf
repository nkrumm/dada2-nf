// TODO: command line parameters for these inputs with these defaults
// in the config file
sample_information = "test/sample-information.csv"
fastq_list = "test/fastq-list.txt"

sample_info = Channel.fromPath(sample_information)
fastq_files = Channel.fromPath(fastq_list)
    .splitText()
    .map { file(it.trim()) }
    .map { [(it.fileName =~ /(^[-a-zA-Z0-9]+)/)[0][0], it ] }
    .groupTuple()
    .map { [ it[0], it[1].sort() ] }
    .map { it.flatten() }


process read_manifest {

    input:
	file("sample-information.csv") from sample_info
    file("fastq-files.txt") from Channel.fromPath(fastq_list)

    output:
	file("batches.csv") into batches

    publishDir params.output, overwrite: true

    """
    manifest.py --outfile batches.csv sample-information.csv fastq-files.txt
    """
}


process barcodecop {

    input:
	tuple sampleid, file(I1), file(I2), file(R1), file(R2) from fastq_files

    output:
	tuple sampleid, file("${sampleid}_R1_.fq.gz"), file("${sampleid}_R2_.fq.gz") into bcop_filtered
    tuple file("${sampleid}_R1_counts.csv"), file("${sampleid}_R2_counts.csv") into bcop_counts

    publishDir "${params.output}/barcodecop/", overwrite: true

    """
    barcodecop --fastq ${R1} ${I1} ${I2} \
        --outfile ${sampleid}_R1_.fq.gz --read-counts ${sampleid}_R1_counts.csv \
        --quiet --match-filter
    barcodecop --fastq ${R2} ${I1} ${I2} \
        --outfile ${sampleid}_R2_.fq.gz --read-counts ${sampleid}_R2_counts.csv \
        --quiet --match-filter
    """
}


process bcop_counts_concat {

    input:
	file("counts*.csv") from bcop_counts.collect()

    output:
	file("bcop_counts.csv") into bcop_counts_concat

    publishDir "${params.output}", overwrite: true

    // TODO: barcodecop should have --sampleid argument to pass through to counts

    """
    echo "sampleid,raw,barcodecop" > bcop_counts.csv
    cat counts*.csv | sed 's/_R[12]_.fq.gz//g' | sort | uniq >> bcop_counts.csv
    """
}

// bcop_filtered.println { "Received: $it" }

// TODO: define a variable min_reads for filtering
to_filter = bcop_counts_concat
    .splitCsv(header: true)
    .filter{ it['barcodecop'].toInteger() > 0 }
    .cross(bcop_filtered)
    .map{ it[1] }

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


process filter_and_trim {

    input:
	tuple sampleid, file(R1), file(R2) from to_filter

    output:
	tuple sampleid, file("${sampleid}_R1_filt.fq.gz"), file("${sampleid}_R2_filt.fq.gz") into filtered_trimmed

    publishDir "${params.output}/filtered/", overwrite: true

    // TODO: variables in config for filter and trim params
    """
    dada2_filter_and_trim.R \
        --infiles ${R1} ${R2} \
        --outfiles ${sampleid}_R1_filt.fq.gz ${sampleid}_R2_filt.fq.gz \
	--trim-left 15 \
	--f-trunc 280 \
	--r-trunc 250 \
	--truncq 2
    """
}


// [sampleid, batch, R1, R2]
batches
    .splitCsv(header: false)
    .join(filtered_trimmed)
    .into { to_learn_errors ; to_dereplicate }


process learn_errors {

    input:
	tuple batch, R1s, R2s from to_learn_errors.map{ it[1, 2, 3] }.groupTuple()

    output:
	file("error_model_${batch}.rds") into error_models
    file("error_model_${batch}.png") into error_model_plots

    publishDir "${params.output}", overwrite: true

    // https://github.com/nextflow-io/nextflow/issues/774
    // TODO: use file() to stage inputs somehow?

    """
    echo "${R1s.join('\n')}" > R1.txt
    echo "${R2s.join('\n')}" > R2.txt
    dada2_learn_errors.R --r1 R1.txt --r2 R2.txt \
        --model error_model_${batch}.rds \
        --plots error_model_${batch}.png \
        --nthreads 10
    """
}


process dada_dereplicate {

    input:
	tuple sampleid, batch, file(R1), file(R2) from to_dereplicate
    file("") from error_models.collect()

    output:
	file("dada.rds") into dada_data
    file("seqtab.csv") into dada_seqtab
    file("counts.csv") into dada_counts
    file("overlaps.csv") into dada_overlaps

    publishDir "${params.output}/${sampleid}/", overwrite: true

    // TODO: set --self-consist to TRUE in production

    """
    dada2_dada.R ${R1} ${R2} --errors error_model_${batch}.rds \
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

process combined_counts {

    input:
	file("*.csv") from dada_counts.collect()

    output:
	file("dada_counts.csv")

    publishDir params.output, overwrite: true

    """
    csvcat.sh *.csv > dada_counts.csv
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
    file('ssu.cm') from file("data/ssu-align-0.1.1-bacteria-0p1.cm")

    output:
	file("seqs.sto")
    file("sv_aln_scores.txt") into aln_scores

    publishDir params.output, overwrite: true

    // TODO: how to best specify cpu usage by cmalign?

    """
    cmalign --cpu 10 --dnaout --noprob \
        -o seqs.sto --sfile sv_aln_scores.txt ssu.cm seqs.fasta
    """
}

process filter_16s {

    input:
	file("seqs.fasta") from seqs_to_filter
    file("sv_aln_scores.txt") from aln_scores

    output:
	file("16s.fasta")
    file("not16s.fasta")
    file("16s-outcomes.csv")

    publishDir params.output, overwrite: true

    """
    filter_16s.py seqs.fasta sv_aln_scores.txt \
	--min-bit-score 0 \
	--passing 16s.fasta \
	--failing not16s.fasta \
        --outcomes 16s-outcomes.csv
    """
}
