 #!/usr/bin/env nextflow

 include {   BUNDLEPARC         } from './subworkflows/local/bundleparc'
 include {   PREPROC_DWI        } from './subworkflows/nf-neuro/preproc_dwi/main'
 include {   BETCROP_DWI2MASK   } from './modules/nf-neuro/betcrop/dwi2mask/main' 
 include {   CHECK_STRIDE       } from './modules/local/dwi/checkstride'
 include {   RECONST_FRF        } from './modules/nf-neuro/reconst/frf/main'
 include {   RECONST_MEANFRF    } from './modules/nf-neuro/reconst/meanfrf/main'
 include {   RECONST_DTIMETRICS } from './modules/nf-neuro/reconst/dtimetrics/main'
 include {   RECONST_FODF       } from './modules/nf-neuro/reconst/fodf/main'

 workflow {

     ch_versions = Channel.empty()
      if ( params.fodf && params.dwi ) {
        error "Can only specify either --dwi or --fodf but not both. See USAGE for instructions."
     }
     else if ( params.fodf ) {

         input = file(params.fodf)
         // ** Loading FODF files. ** //
         fodf_channel = Channel.fromFilePairs("$input/**/*fodf.nii.gz", size: 1, flat: true)
             { it.parent.name } // Set the subject filename as subjectID + '_' + session.
             .map{ sid, fodf -> [ [id: sid], fodf ] }

     }
     else if ( params.dwi ) {

        input = file(params.dwi)
        ch_sid_dwi = Channel
            .fromFilePairs("$input/**/*{bval,bvec,dwi.nii.gz}",
                         size: 3,
                         flat: true) { it.parent.name } // Set the subject filename as subjectID + '_' + session.
             .map{ sid, bval, bvec, dwi -> [ [id: sid], dwi, bval, bvec ] }

        ch_sid_rev_b0 = Channel
            .fromPath("$input/**/*rev_b0.nii.gz")
            .map{ [it.parent.name, it] } // Set the subject filename as subjectID + '_' + session.
            .map{ sid, revb0 -> [ [id: sid], revb0 ] }

        CHECK_STRIDE ( ch_sid_dwi )

        ch_versions = ch_versions.mix(CHECK_STRIDE.out.versions.first())

        ch_preproc_dwi = CHECK_STRIDE.out.dwi
            .join(CHECK_STRIDE.out.bval)
            .join(CHECK_STRIDE.out.bvec)

        if ( params.preproc ) {

            PREPROC_DWI(
                ch_preproc_dwi,
                Channel.empty(),
                ch_sid_rev_b0,
                Channel.empty(),
                Channel.empty()
            )

            ch_versions = ch_versions.mix(PREPROC_DWI.out.versions.first())

            ch_dti_metrics = PREPROC_DWI.out.dwi
                .join(PREPROC_DWI.out.bval)
                .join(PREPROC_DWI.out.bvec)
                .join(PREPROC_DWI.out.b0_mask)

        }
        else {
            BETCROP_DWI2MASK( ch_preproc_dwi )
            ch_versions = ch_versions.mix(BETCROP_DWI2MASK.out.versions.first())

            ch_dti_metrics = ch_preproc_dwi
                .join(BETCROP_DWI2MASK.out.mask)
        }
        // MODULE: Run RECONST/DTIMETRICS
        RECONST_DTIMETRICS( ch_dti_metrics )
        ch_versions = ch_versions.mix(RECONST_DTIMETRICS.out.versions.first())

        // MODULE: Run RECONST/FRF
        //
        ch_reconst_frf = ch_dti_metrics
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
        ch_reconst_fodf = ch_dti_metrics
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
         log.info "                    |    ├-- *dwi.bvec"
         log.info "                    |    ├-- *rev_b0.nii.gz (optional)"
         log.info "                    └-- S2" 
         log.info "                         ├-- *dwi.nii.gz"
         log.info "                         ├-- *dwi.bval"
         log.info "                         ├-- *dwi.bvec"
         log.info "                         └-- *rev_b0.nii.gz (optional)"
         log.info "Or :"
         log.info "    --fodf=/path/to/[input]   Input directory containing your subjects"
         log.info "                    |"
         log.info "                    ├-- S1"
         log.info "                    |    ├-- *fodf.nii.gz"
         log.info "                    └-- S2"
         log.info "                         └-- *fodf.nii.gz"
         log.info ""

         error "Please resubmit your command with the previous file structure."
     }

     BUNDLEPARC ( fodf_channel )
     ch_versions = ch_versions.mix(BUNDLEPARC.out.versions.first())
 }
