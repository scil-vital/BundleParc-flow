 #!/usr/bin/env nextflow

 include { BUNDLE_BUNDLEPARC } from './modules/local/bundle/bundleparc'

 workflow get_data {
     main:
         if ( !params.input ) {
             log.info "You must provide an input directory containing all images using:"
             log.info ""
             log.info "    --input=/path/to/[input]   Input directory containing your subjects"
             log.info "                        |"
             log.info "                        ├-- S1"
             log.info "                        |    ├-- *fodf.nii.gz"
             log.info "                        └-- S2"
             log.info "                             └-- *fodf.nii.gz"
             log.info ""
             error "Please resubmit your command with the previous file structure."
         }

         input = file(params.input)
         // ** Loading FODF files. ** //
         fodf_channel = Channel.fromFilePairs("$input/**/**/*fodf.nii.gz", size: 1, flat: true)
             { it.parent.parent.name + "_" + it.parent.name } // Set the subject filename as subjectID + '_' + session.
             .map{ sid, fodf -> [ [id: sid], fodf ] }
     emit:
         fodf = fodf_channel
 }

 workflow {
     inputs = get_data()

     BUNDLE_BUNDLEPARC ( inputs.fodf )
 }
