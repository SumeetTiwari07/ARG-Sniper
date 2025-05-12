#!/usr/bin/env nextflow

//1. DSL: Using DSL-2
nextflow.enable.dsl=2

//2. Default parameters: All of the default parameters are being set in `nextflow.config`

//3. if `true` this prevents a warning of undefined parameter 
params.help = false

//4. Help menu: Function which prints help message text
log.info """
QIB: NF ARG-SNIPER (by default)
=====================================
reads               : ${params.reads}
grootdb             : ${params.grootdb}
aribadb             : ${params.aribadb}
kargadb             : ${params.kargadb}
srst2db             : ${params.srst2db}
groot_cov           : ${params.groot_cov}
output              : ${params.output}
work_dir            : ${params.work_dir}
"""
.stripIndent()
//4. 1 Help if --help is specified.

def helpMessage() {
    log.info """
Usage:
    nextflow run ARG-Sniper-pipeline.nf --offline -with-report <ARGUMENTS>

Required Arguments:
    Input:
        --reads       Folder containing reads with file name *_R{1,2}.fastq.gz
        --gootdb      Path of indexed GROOT database
        --aribadb     Path to ARIBA database
        --kargadb     Path to KARG database
        --srst2db     Path to SRST2 database
        --output      Folder for output files    

# By default, the pipeline will run all supported tools.
Optional Arguments:
    Skipping specific tools:
        --skip_groot      Skip running GROOT
        --skip_kma        Skip running KMA
        --skip_ariba      Skip running ARIBA
        --skip_karga      Skip running KARGA
        --skip_srst2      Skip running SRST2
"""
}

// Show help message if the user specifies the --help flag at runtime
if ( params.help ){
    // Invoke the function above which prints the help message
    helpMessage()
    // Exit out and do not run anything else
    exit 1
}
/*
 * Defining the output folders. if required, then
 */
grootOutputDir = "${params.output}/groot_results"
aribaOutputDir = "${params.output}/ariba_results"
srst2OutputDir = "${params.output}/srst2_results"
kargaOutputDir = "${params.output}/karga_results"
argprofilerOutputDir = "${params.output}/argprofiler_results"

//5. IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
include { groot_align } from './modules/groot' addParams(OUTPUT: grootOutputDir)
include { ariba_run } from './modules/ariba' addParams(OUTPUT: aribaOutputDir)
include { ariba_summary } from './modules/ariba' addParams(OUTPUT: aribaOutputDir)
include { srst2 } from './modules/srst2' addParams(OUTPUT: srst2OutputDir)
include { karga } from './modules/karga' addParams(OUTPUT: kargaOutputDir)
include { kma_align } from './modules/argprofiler' addParams(OUTPUT: argprofilerOutputDir)


// Define the pattern which will be used to find the FASTQ files
fastq_pattern = "${params.reads}"

// Set up a channel from the pairs of files found with that pattern
fastq_ch = Channel
    .fromFilePairs(fastq_pattern)
    .ifEmpty { error "No files found matching the pattern ${fastq_pattern}" }
    .map{
        [it[0], it[1][0], it[1][1]]
        }

// Main workflow
// Set default values to skip a tool default: run all
params.skip_groot = false
params.skip_kma = false
params.skip_ariba = false
params.skip_karga = false
params.skip_srst2 = false

workflow {

    if (!params.skip_groot) {
        groot_align(fastq_ch)
    }

    if (!params.skip_kma) {
        kma_align(fastq_ch)
    }

    if (!params.skip_ariba) {
        ariba_reports_ch = ariba_run(fastq_ch)
        ariba_reports_ch.collect().set { collected_reports_ch }
        ariba_summary(collected_reports_ch)
    }

    if (!params.skip_karga) {
        karga(fastq_ch)
    }

    if (!params.skip_srst2) {
        srst2(fastq_ch)
    }
}