# BundleParc-flow

BundleParc-flow is a workflow for parcellating white matter bundles from diffusion MRI using [BundleParc](https://github.com/scil-vital/BundleParc) and nextflow.

Paper submitted to Medical Image Analysis. In the meantime, please contact us for acknowledgments.

## Requirements

- [Nextflow](https://www.nextflow.io/)
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/docs/)

## Installation
1. Clone the repository:

   ```bash
   git clone git@github.com:scil-vital/BundleParc-flow.git
   cd BundleParc-flow
    ```
That's it ! 

## Usage

1. From FOD
  ```bash
  nextflow run main.nf --fodf <input> -profile docker
  ```
2. From DWI
  ```bash
  nextflow run main.nf --dwi <input> -profile docker
  ```

See USAGE for more instructions on how to run the workflow.
