//
// Subworkflow with functionality specific to the scil-vital/bundleparc-flow pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    input             //  string: Path to input samplesheet
    help              // boolean: Display help message and exit
    help_full         // boolean: Show the full help message
    show_hidden       // boolean: Show hidden parameters in the help message

    main:

    ch_versions = channel.empty()
    ch_samplesheet = channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        false   // Reinstate when/if we use conda/mamba :
                // workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )
    //
    // Validate parameters and generate parameter summary to stdout
    //
    command = "nextflow run ${workflow.manifest.name} -profile <docker/singularity/.../institute> --input samplesheet.csv --outdir <OUTDIR>"
    before_text = """
-\033[2m----------------------------------------------------------------------------------\033[0m-

 \033[0;35m  scil-vital/BundleParc-flow ${workflow.manifest.version}\033[0m
-\033[2m----------------------------------------------------------------------------------\033[0m-
    """
    after_text = """${workflow.manifest.doi ? "\n* The pipeline\n" : ""}${workflow.manifest.doi.tokenize(",").collect { "    https://doi.org/${it.trim().replace('https://doi.org/','')}"}.join("\n")}${workflow.manifest.doi ? "\n" : ""}
    * The nf-neuro project
        https://scilus.github.io/nf-neuro

    * The nf-core framework
        https://doi.org/10.1038/s41587-020-0439-x

    * Software dependencies
        https://github.com/scil-vital/bundleparc-flow/blob/master/CITATIONS.md
    """

    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null,
        help,
        help_full,
        show_hidden,
        before_text,
        after_text,
        command
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE (
        nextflow_cli_args
    )

    //
    // Create channel from input file provided through params.input
    //
    if ( params.input ) {
    input = file(params.input)
    ch_sid_dwi = Channel
        .fromFilePairs("$input/**/*{bval,bvec,dwi.nii.gz}",
                     size: 3,
                     flat: true) { it.parent.name } // Set the subject filename as subjectID + '_' + session.
         .map{ sid, bval, bvec, dwi -> [ [id: sid], dwi, bval, bvec ] }
    }
    else {
        log.info "You must provide an input directory containing all images using:"
        log.info ""
        log.info "    --dwi=/path/to/[input]   Input directory containing your subjects"
        log.info "                    |"
        log.info "                    ├-- S1"
        log.info "                    |    ├-- *dwi.nii.gz"
        log.info "                    |    ├-- *dwi.bval"
        log.info "                    |    └-- *dwi.bvec"
        log.info "                    └-- S2" 
        log.info "                         ├-- *dwi.nii.gz"
        log.info "                         ├-- *dwi.bval"
        log.info "                         └-- *dwi.bvec"
        log.info ""
        error "Please resubmit your command with the previous file structure."
    }
    
    emit:
    ch_sid_dwi = ch_sid_dwi
}
