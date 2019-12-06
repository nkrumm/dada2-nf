// fastq = Channel.fromPath("test/fastq/*").collect()

// Channel.fromPath("test/fastq-list.txt")
//     .splitText()
//     .map { file(it) }
//     .into { fastq_files }

// TODO: command line parameters for these inputs with these defaults in the config file
sample_information = "test/sample-information.csv"
fastq_list = "test/fastq-list.txt"

sample_info = Channel.fromPath(sample_information)
fastq_files = Channel.fromPath(fastq_list)
    .splitText()
    .map { it - ~/\s+/ }  // strip whitespace
    .map { file(it) }
    .map { it -> [(it.fileName =~ /(^[-a-zA-Z0-9]+)/)[0][0], it ] }
    .groupTuple()
    .map { it -> it.flatten() }
fastq_files2 = Channel.fromPath(fastq_list)

// fastq_files.println { "Received: $it" }

process read_manifest {

    // container null

    input:
    file("sample-information.csv") from sample_info
    file("fastq-files.txt") from fastq_files2

    output:
    file("batches.csv") into batches

    publishDir params.output, overwrite: true

    """
    manifest.py --outfile batches.csv sample-information.csv fastq-files.txt
    """
}

process barcodecop {
    input:
	tuple sampleid, I1, I2, R1, R2 from fastq_files

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
    tuple sampleid, R1, R2 from to_filter

    output:
    tuple sampleid, file("${sampleid}_R1_.fq.gz"), file("${sampleid}_R2_.fq.gz") into filtered_trimmed

    publishDir "${params.output}/filtered/", overwrite: true

    // TODO: variables in config for filter and trim params
    """
    dada2_filter_and_trim.R \
        --infiles ${R1} ${R2} \
        --outfiles ${sampleid}_R1_.fq.gz ${sampleid}_R2_.fq.gz \
	--trim-left 15 \
	--f-trunc 280 \
	--r-trunc 250 \
	--truncq 2
    """
}

// [[batch, [r1...], [r2...]], ...]
to_learn_errors = batches
    .splitCsv(header: true)
    .cross(filtered_trimmed)
    .map{ it -> [it[0]['batch'], it[1][1], it[1][2]] }
    .groupTuple()
    // .println { "Received: $it" }

// // clone channel so that it can be consumed twice
// filtered.into { filtered_learn_errors; filtered_dada }

// process learn_errors {

//     input:
//     tuple batch, file("") from filtered_learn_errors

//     output:
//     tuple batch, file("error_model.rds") into error_model
//     file("error_model.png") into error_model_plots

//     publishDir "${params.output}/batch_${batch}/", overwrite: true

//     """
//     dada2_learn_errors.R . --model error_model.rds --plots error_model.png --nthreads 10
//     """
// }

// // prepare input for dada_dereplicate
// // returns channel of [batch, model, sampleid, R1, R2]
// // https://www.nextflow.io/docs/latest/operator.html
// error_model
//     .join(filtered_dada)
//     .map { x -> [x[0], x[1], x[2].collate(2)] }
//     .transpose()
//     .map { y -> y.flatten() }
//     .map { z -> [z[0], z[1], file(z[2]).baseName.replaceFirst(/_R1_filt.*/, ""), z[2], z[3]] }
//     .set { dada_input }

// process dada_dereplicate {

//     input:
// 	tuple batch, file("model.rds"), sampleid, \
//     file("R1.fastq.gz"), file("R2.fastq.gz") from dada_input

//     output:
// 	file("dada.rds") into dada_data
//     file("seqtab.csv") into dada_seqtab
//     file("counts.csv") into dada_counts
//     file("overlaps.csv") into dada_overlaps

//     publishDir "${params.output}/${sampleid}/", overwrite: true

//     // TODO: set --self-consist to TRUE in production

//     """
//     dada2_dada.R R1.fastq.gz R2.fastq.gz --errors model.rds \
// 	--sampleid ${sampleid} \
// 	--self-consist FALSE \
// 	--data dada.rds \
// 	--seqtab seqtab.csv \
// 	--counts counts.csv \
// 	--overlaps overlaps.csv
//     """
// }

// process combined_overlaps {

//     input:
//     file("overlaps_*.csv") from dada_overlaps.collect()

//     output:
//     file("overlaps.csv")

//     publishDir params.output, overwrite: true

//     """
//     csvcat.sh overlaps_*.csv > overlaps.csv
//     """
// }

// process write_seqs {

//     input:
//     file("seqtab_*.csv") from dada_seqtab.collect()

//     output:
//     file("seqs.fasta") into seqs
//     file("specimen_map.csv")
//     file("dada2_sv_table.csv")
//     file("dada2_sv_table_long.csv")
//     file("weights.csv")

//     publishDir params.output, overwrite: true

//     """
//     write_seqs.py seqtab_*.csv \
// 	--seqs seqs.fasta \
// 	--specimen-map specimen_map.csv \
// 	--sv-table dada2_sv_table.csv \
// 	--sv-table-long dada2_sv_table_long.csv \
// 	--weights weights.csv
//     """
// }

// // clone channel so that it can be consumed twice
// seqs.into { seqs_to_align; seqs_to_filter }

// process cmalign {

//     input:
//     file("seqs.fasta") from seqs_to_align
//     file('ssu-align-0.1.1-bacteria-0p1.cm') from file("data/ssu-align-0.1.1-bacteria-0p1.cm")

//     output:
//     file("seqs.sto")
//     file("sv_aln_scores.txt") into aln_scores

//     publishDir params.output, overwrite: true

//     """
//     cmalign \
// 	--cpu 10 --dnaout --noprob \
// 	-o seqs.sto \
// 	--sfile sv_aln_scores.txt ssu-align-0.1.1-bacteria-0p1.cm seqs.fasta
//     """
// }

// process filter_16s {

//     input:
// 	file("seqs.fasta") from seqs_to_filter
//     file("sv_aln_scores.txt") from aln_scores

//     output:
// 	file("16s.fasta")
//         file("not16s.fasta")

//     publishDir params.output, overwrite: true

//     """
//     filter_16s.py seqs.fasta sv_aln_scores.txt \
// 	--min-bit-score 0 \
// 	--passing 16s.fasta \
// 	--failing not16s.fasta
//     """
// }
