#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// Align a genome with groot
process groot_align {
    container "${params.container__groot}"
    publishDir params.OUTPUT, mode: 'copy'

    input:
    tuple val(sample_name), path(R1_fastq), path(R2_fastq)

    output:
    path "groot_report_${sample_name}.tsv"
    path "groot_${sample_name}.log"

    shell:
    '''
    groot align -i !{params.grootdb}  -f !{R1_fastq},!{R2_fastq} -p !{params.NCPUS} | groot report -c !{params.groot_cov} > groot_report_!{sample_name}.tsv
    mv groot.log groot_!{sample_name}.log
    '''
}
