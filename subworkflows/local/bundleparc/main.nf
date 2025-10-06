include { BUNDLE_BUNDLEPARC } from '../../../modules/local/bundle/bundleparc'

def fetch_bundleparc_checkpoint(weightsUrl, dest) {

    def path = java.nio.file.Paths.get("$dest/weights/")
    def parentDir = path.getParent()
    if (!java.nio.file.Files.exists(path)) {
        java.nio.file.Files.createDirectories(path)
    }

    def weights = new File("$dest/weights/123_4_5_bundleparc.ckpt").withOutputStream { out ->
        new URL(weightsUrl).withInputStream { from -> out << from; }
    }
}

workflow BUNDLEPARC {

    take:
        ch_fodf // channel: [ val(meta), [ fodf ] ]

    main:

        ch_versions = Channel.empty()

        if ( params.checkpoint ) {
            weights = Channel.fromPath("$params.checkpoint", checkIfExists: true, relative: true)
        }

        else {
            if ( !file("$workflow.workDir/weights/123_4_5_bundleparc.ckpt").exists() ) {
            fetch_bundleparc_checkpoint("https://zenodo.org/records/15579498/files/123_4_5_bundleparc.ckpt",
                                    "${workflow.workDir}/")
            }
            weights = Channel.fromPath("$workflow.workDir/weights/123_4_5_bundleparc.ckpt", checkIfExists: true)
        }

        // ** Register the weights to subject's space. Set up weights file as moving image ** //
        // ** and subject anat as fixed image.                                         ** //
        ch_fodf =  ch_fodf.combine(weights)

        BUNDLE_BUNDLEPARC( ch_fodf)

    emit:
        bundles = BUNDLE_BUNDLEPARC.out.labels // channel: [ val(meta), [ bundles ] ]

        versions = ch_versions                 // channel: [ versions.yml ]
}
