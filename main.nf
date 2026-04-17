 #!/usr/bin/env nextflow

include {   BUNDLEPARC         } from './subworkflows/local/bundleparc'
include {   BETCROP_DWI2MASK   } from './modules/nf-neuro/betcrop/dwi2mask/main' 
include {   CHECK_STRIDE       } from './modules/local/dwi/checkstride'
include {   RECONST_FRF        } from './modules/nf-neuro/reconst/frf/main'
include {   RECONST_DTIMETRICS } from './modules/nf-neuro/reconst/dtimetrics/main'
include {   RECONST_FODF       } from './modules/nf-neuro/reconst/fodf/main'

 workflow {

    ch_versions = Channel.empty()
    if ( params.dwi ) {

        input = file(params.dwi)
        ch_sid_dwi = Channel
            .fromFilePairs("$input/**/*{bval,bvec,dwi.nii.gz}",
                         size: 3,
                         flat: true) { it.parent.name } // Set the subject filename as subjectID + '_' + session.
             .map{ sid, bval, bvec, dwi -> [ [id: sid], dwi, bval, bvec ] }

        CHECK_STRIDE ( ch_sid_dwi )

        ch_versions = ch_versions.mix(CHECK_STRIDE.out.versions.first())

        ch_preproc_dwi = CHECK_STRIDE.out.dwi
            .join(CHECK_STRIDE.out.bval)
            .join(CHECK_STRIDE.out.bvec)
        BETCROP_DWI2MASK( ch_preproc_dwi )
        ch_versions = ch_versions.mix(BETCROP_DWI2MASK.out.versions.first())

        ch_dti_metrics = ch_preproc_dwi
            .join(BETCROP_DWI2MASK.out.mask)
        // MODULE: Run RECONST/DTIMETRICS

        RECONST_DTIMETRICS( ch_dti_metrics )
        ch_versions = ch_versions.mix(RECONST_DTIMETRICS.out.versions.first())

        // MODULE: Run RECONST/FRF
        //
        ch_reconst_frf = CHECK_STRIDE.out.dwi
            .join(CHECK_STRIDE.out.bval)
            .join(CHECK_STRIDE.out.bvec)
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
        ch_reconst_fodf = CHECK_STRIDE.out.dwi
            .join(CHECK_STRIDE.out.bval)
            .join(CHECK_STRIDE.out.bvec)
            .join(BETCROP_DWI2MASK.out.mask)
            .join(RECONST_DTIMETRICS.out.fa)
            .join(RECONST_DTIMETRICS.out.md)
            .join(ch_fiber_response)

        RECONST_FODF( ch_reconst_fodf )
        ch_versions = ch_versions.mix(RECONST_FODF.out.versions.first())

        fodf_channel = RECONST_FODF.out.fodf 
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

     BUNDLEPARC ( fodf_channel )
     ch_versions = ch_versions.mix(BUNDLEPARC.out.versions.first())
 }
