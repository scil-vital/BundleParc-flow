
process CHECK_STRIDE {
    tag "$meta.id"

    container "mrtrix3/mrtrix3:3.0.5"

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

    stride="\$( mrinfo -stride $dwi )"
    if [[ "\$stride" == "-1 2 3 4" ]]; then
        ln -s $dwi ${prefix}__dwi_stride_corrected.nii.gz
        ln -s $bvec ${prefix}__dwi_stride_corrected.bvec
        ln -s $bval ${prefix}__dwi_stride_corrected.bval
    else
        mrconvert $dwi ${prefix}__dwi_stride_corrected.nii.gz -stride "-1 2 3 4"
        dwigradcheck $dwi -fslgrad $bvec $bval \
            -export_grad_fsl ${prefix}__dwi_stride_corrected.bvec \
            ${prefix}__dwi_stride_corrected.bval
    fi

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
