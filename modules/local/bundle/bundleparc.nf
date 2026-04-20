process BUNDLE_BUNDLEPARC {
    tag "$meta.id"
    label 'process_single'
    label 'process_gpu'
    errorStrategy 'ignore'

    container "${ task.ext.gpu ?
        "scilus/scilpy:2.2.2_gpu" :
        "scilus/scilpy:2.2.2_cpu" }"

    input:
        tuple val(meta), path(fodf), path(checkpoint)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.nii.gz"), emit: labels
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def nb_pts = task.ext.nb_pts ? "--nb_pts " + task.ext.nb_pts : ""
    def mm = task.ext.mm ?: ''
    def keep_biggest = task.ext.keep_biggest_blob ?: ''
    def min_blob_size = task.ext.min_blob_size ?: ''
    def half = task.ext.half_precision ?: ''
    def continuous = task.ext.continuous ?: ''

    """

    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1

    scil_fodf_bundleparc $fodf --out_prefix ${prefix}__ ${nb_pts} ${mm} ${continuous} ${min_blob_size} ${keep_biggest} ${half} --out_dir tmp --checkpoint ${checkpoint} --volume_size 144 -v DEBUG
    mv tmp/* .
    rm -r tmp

    cat <<-BUNDLEPARC_INFO > ${prefix}__bundleparc_config.json
    {"nb_pts": "${task.ext.nb_pts}"}
    BUNDLEPARC_INFO

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scil_fodf_bundleparc -h

    touch ${prefix}__AF_left.nii.gz
    ${prefix}__bundleparc_config.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
