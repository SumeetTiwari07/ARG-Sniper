#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// All of the default parameters are being set in `nextflow.config`

// Import modules
include { groot_align } from './modules/groot'
include { ariba_run } from './modules/ariba'
include { ariba_summary } from './modules/ariba'
include { srst2 } from './modules/srst2'
include { karga } from './modules/karga'

// Function which prints help message text
def helpMessage() {
    log.info"""
Usage:

nextflow run ARG-Sniper-pipeline.nf --offline -with-report <ARGUMENTS>

Required Arguments:

  Input Data:
  --fastq_folder                   Folder containing reads with file name *_R{1,2}.fastq.gz,

  Reference Data:
  --indexed_groot_database        Reference database to use

  Output Location:
  --results_dir                 Folder for output files"""

}

params.all = true
params.groot = false
params.ariba = false
params.srst2 = false
params.karga = false
params.help = false

// Main workflow
workflow {

    // Show help message if the user specifies the --help flag at runtime
    // or if any required params are not provided
    if ( params.help || params.results_dir == false || params.fastq_folder == false ){
        // Invoke the function above which prints the help message
        helpMessage()
        // Exit out and do not run anything else
        exit 1
    }

    if ( params.fastq_folder ){

        // Make a channel with the input FASTQ read pairs from the --fastq_folder
        // After calling `fromFilePairs`, the structure must be changed from
        // [specimen, [R1, R2]]
        // to
        // [specimen, R1, R2]
        // with the map{} expression

        // Define the pattern which will be used to find the FASTQ files
        fastq_pattern = "${params.fastq_folder}/*_R{1,2}.fastq.gz"

        // Set up a channel from the pairs of files found with that pattern
        fastq_ch = Channel
            .fromFilePairs(fastq_pattern)
            .ifEmpty { error "No files found matching the pattern ${fastq_pattern}" }
            .map{
                [it[0], it[1][0], it[1][1]]
            }

    }

    if(params.all || params.groot){
        groot_align(
            fastq_ch
        )
    // output:
    //     path(groot_report_<sample_name>.tsv)
    //     path(groot_<sample_name>.tsv)
    }

    if(params.all || params.ariba){
        ariba_report = ariba_run(
            fastq_ch
        )

	ariba_grouped_reports = ariba_report
	   .collect()

	ariba_summary(ariba_grouped_reports)

    // output:
    //     path(ariba_report)
    }

    if(params.all || params.srst2){
        srst2(
            fastq_ch
        )
    // output:
    //     path(srst2_report_<sample_name>.tsv)
    }    

    if(params.all || params.karga){
        karga(
            fastq_ch
        )
    // output:
    //     path(_KARGA_mappedGenes.csv )
    }


}
