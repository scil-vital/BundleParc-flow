
process CHECK_STRIDE {
    tag "$meta.id"

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
                'https://scil.usherbrooke.ca/containers/scilus_2.2.0.sif':
                'scilus/scilus:2.2.0' }"

    input:
        tuple val(meta), path(dwi), path(bval), path(bvec)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*_dwi_stride_corrected.nii.gz"), emit: dwi
    tuple val(meta), path("*_dwi_stride_corrected.bval"),   emit: bval
    tuple val(meta), path("*_dwi_stride_corrected.bvec"),   emit: bvec
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def nb_pts = task.ext.nb_pts ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """

    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1

    mrconvert $dwi ${prefix}__dwi_stride_corrected.nii.gz -stride "-1 2 3 4"
    dwigradcheck $dwi -fslgrad $bvec $bval \
        -export_grad_fsl ${prefix}__dwi_stride_corrected.bvec \
        ${prefix}__dwi_stride_corrected.bval

		cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(dwidenoise -version 2>&1 | sed -n 's/== dwidenoise \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mrconvert -help
    dwigradcheck -help

    touch ${prefix}__dwi_stride_corrected.nii.gz
    touch ${prefix}__dwi_stride_corrected.bvec
    touch ${prefix}__dwi_stride_corrected.bval
    ${prefix}__bundleparc_config.json

		cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(dwidenoise -version 2>&1 | sed -n 's/== dwidenoise \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """
}
