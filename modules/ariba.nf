#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// Align a genome with ariba
process ariba_run {
    container "${params.container__ariba}"
    publishDir params.OUTPUT, mode: 'copy'


    input:
    tuple val(sample_name), path(R1_fastq), path(R2_fastq)

    output:
    path "ariba_report_${sample_name}.tsv"

    shell:
    '''
    ariba run !{params.aribadb} !{R1_fastq} !{R2_fastq} ./results --threads !{params.NCPUS}
    mv results/report.tsv ariba_report_!{sample_name}.tsv
    '''
}

// Summarise ariba results
process ariba_summary {
    container "${params.container__ariba}"
    publishDir params.OUTPUT, mode: 'copy'


    input:
    path(sample_reports)

    output:
    path "ariba_summary.csv"

    shell:
    '''
    ariba summary ariba_summary  !{sample_reports}
    '''
}
