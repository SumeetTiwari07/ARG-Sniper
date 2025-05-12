#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2
//params.OUTPUT="argprofiler_result"

// Align reads to ARGprofiler database
process kma_align {
    container "${params.container__kma}"
    publishDir params.OUTPUT, mode: 'copy'

    input:
    tuple val(sample_name), path(R1_fastq), path(R2_fastq)

    output:
    path "ARGprofiler_report_${sample_name}.txt"

    shell:
    '''
    kma -ipe !{R1_fastq} !{R2_fastq} -o !{sample_name} -t_db !{params.argprofilerdb}/argprofiler.fa -ef -1t1 -nf -vcf -sam -matrix -t !{params.NCPUS} > !{sample_name}.sam 2>log.txt
    Rscript !{projectDir}/bin/mapstatFilters.R -i !{sample_name}.mapstat -o ARGprofiler_report_!{sample_name}.txt -r !{params.argprofilerdb}/gene_length.tsv -d 6
    '''
}

