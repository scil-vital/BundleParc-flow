// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process BUNDLE_BUNDLEPARC {
    tag "$meta.id"
    label 'process_single'
    errorStrategy 'ignore'

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
                'https://scil.usherbrooke.ca/containers/scilus_2.2.0.sif':
                'scilus/scilus:2.2.0' }"

    input:
        tuple val(meta), path(fodf), path(checkpoint)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.nii.gz"), emit: labels
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def nb_pts = task.ext.nb_pts ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """

    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1

    stride="\$( mrinfo -stride $fodf )"
    if [[ "\$stride" == "-1 2 3 4" ]]; then
        scil_fodf_bundleparc $fodf --out_prefix ${prefix}__ --nb_pts ${nb_pts} --out_folder tmp --checkpoint ${checkpoint} --keep_biggest
        mv tmp/* .
        rm -r tmp
    else
        echo "Invalid stride ("\$stride"), must be -1 2 3 4"
        exit 1
    fi

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
