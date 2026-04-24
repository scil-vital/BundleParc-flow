/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include {   BUNDLEPARC         } from '../subworkflows/nf-neuro/bundleparc'
include {   BETCROP_DWI2MASK   } from '../modules/nf-neuro/betcrop/dwi2mask/main' 
include {   IMAGE_CONVERTDWI   } from '../modules/nf-neuro/image/convertdwi'
include {   RECONST_FRF        } from '../modules/nf-neuro/reconst/frf/main'
include {   RECONST_DTIMETRICS } from '../modules/nf-neuro/reconst/dtimetrics/main'
include {   RECONST_FODF       } from '../modules/nf-neuro/reconst/fodf/main'

workflow BUNDLEPARC_FLOW {

    take:
    ch_dwi_bval_bvec
    main:

    ch_versions = Channel.empty()

        
    IMAGE_CONVERTDWI ( ch_dwi_bval_bvec )

    ch_versions = ch_versions.mix(IMAGE_CONVERTDWI.out.versions.first())

    ch_preproc_dwi = IMAGE_CONVERTDWI.out.image
        .join(IMAGE_CONVERTDWI.out.bval)
        .join(IMAGE_CONVERTDWI.out.bvec)
    BETCROP_DWI2MASK( ch_preproc_dwi )
    ch_versions = ch_versions.mix(BETCROP_DWI2MASK.out.versions.first())

    ch_dti_metrics = ch_preproc_dwi
        .join(BETCROP_DWI2MASK.out.mask)
    // MODULE: Run RECONST/DTIMETRICS

    RECONST_DTIMETRICS( ch_dti_metrics )
    ch_versions = ch_versions.mix(RECONST_DTIMETRICS.out.versions.first())

    // MODULE: Run RECONST/FRF
    //
    ch_reconst_frf = IMAGE_CONVERTDWI.out.image
        .join(IMAGE_CONVERTDWI.out.bval)
        .join(IMAGE_CONVERTDWI.out.bvec)
        .join(BETCROP_DWI2MASK.out.mask)
        .map { it + [[], [], []] }

    RECONST_FRF( ch_reconst_frf )
    ch_versions = ch_versions.mix(RECONST_FRF.out.versions.first())

    /* Run fiber response averaging over subjects */
    ch_single_frf = RECONST_FRF.out.frf
        .map{ it + [[], []] }
                                                        
    ch_fiber_response = RECONST_FRF.out.wm_frf
        .join(RECONST_FRF.out.gm_frf)
        .join(RECONST_FRF.out.csf_frf)
        .mix(ch_single_frf)
    //
    // MODULE: Run RECONST/FODF
    //
    ch_reconst_fodf = IMAGE_CONVERTDWI.out.image
        .join(IMAGE_CONVERTDWI.out.bval)
        .join(IMAGE_CONVERTDWI.out.bvec)
        .join(BETCROP_DWI2MASK.out.mask)
        .join(RECONST_DTIMETRICS.out.fa)
        .join(RECONST_DTIMETRICS.out.md)
        .join(ch_fiber_response)

    RECONST_FODF( ch_reconst_fodf )
    ch_versions = ch_versions.mix(RECONST_FODF.out.versions.first())

    fodf_channel = RECONST_FODF.out.fodf 

    BUNDLEPARC ( fodf_channel )
    ch_versions = ch_versions.mix(BUNDLEPARC.out.versions.first())

 }
