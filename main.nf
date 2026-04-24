#!/usr/bin/env nextflow

include { BUNDLEPARC_FLOW } from './workflows/bundleparc-flow'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_bundleparc-flow_pipeline'

workflow SCILVITAL_BUNDLEPARC_FLOW {

    take:
    ch_dwi_bval_bvec // channel: dwi_bval_bvec read from --input

    main:

    BUNDLEPARC_FLOW ( ch_dwi_bval_bvec )

}

workflow {

    main:

    // SUBWORKFLOW: Run initialisation tasks
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input,
        params.help,
        params.help_full,
        params.show_hidden
    )

    // WORKFLOW: Run main workflow
    SCILVITAL_BUNDLEPARC_FLOW(
        PIPELINE_INITIALISATION.out.ch_dwi_bval_bvec
    )

}
