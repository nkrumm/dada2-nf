fastq = Channel.fromPath( 'test/fastq/*' ).collect()
sample_info = Channel.fromPath( 'test/sample-information.csv' )

process create_manifest {
  input:
  file 'test/sample-information.csv' from sample_info
  file 'test/fastq/' from fastq

  output:
  file 'manifest.csv' into manifest

  """
  manifest.py --outfile manifest.csv test/sample-information.csv test/fastq/
  """
}

// process barcodecop {
//     // container "${container__barcodecop}"
// 
//     input:
//     set specimen, batch, file(R1), file(R2), file(I1), file(I2) from to_bcc_ch
// 
//     output:
//     set specimen, batch, file("${R1.getSimpleName()}.bcc.fq.gz"), file("${R2.getSimpleName()}.bcc.fq.gz") into bcc_to_ft_ch
//     set specimen, batch, file("${R1.getSimpleName()}.bcc.fq.gz"), file("${R2.getSimpleName()}.bcc.fq.gz") into bcc_empty_ch
// 
//     """
//     barcodecop \
//     ${I1} ${I2} \
//     --match-filter \
//     -f ${R1} \
//     -o ${R1.getSimpleName()}.bcc.fq.gz &&
//     barcodecop \
//     ${I1} ${I2} \
//     --match-filter \
//     -f ${R2} \
//     -o ${R2.getSimpleName()}.bcc.fq.gz
//     """
// }
