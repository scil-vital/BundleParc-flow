# BundleParc-flow

BundleParc-flow is a workflow for parcellating white matter bundles from diffusion MRI using [BundleParc](https://github.com/scil-vital/BundleParc) and nextflow.

Paper submitted to Medical Image Analysis. In the meantime, please contact us for acknowledgments.

## Requirements

- [Nextflow](https://www.nextflow.io/)
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/docs/)

## Usage

```bash
nextflow run scil-vital/BundleParc-flow --dwi <input> -profile docker --nb_pts <nb>
```

Options:
- `--dwi` : path to the input diffusion MRI (see USAGE for file structure)
- `--nb_pts <NB>` : number of labels to parcellate the bundles into (default: 10)
- `--mm <NN>` : whether to use millimeters as unit for the parcellation (default: false, i.e. use percentage of the bundle length)
- `--continuous` : whether to use continuous parcellation (default: false, i.e. use discrete parcellation)
- `--min_blob_size <NB>` : minimum size of the blobs in voxels(default: 50 voxels). Smaller blobs will be pruned.
- `--keep_biggest_blob` : whether to keep only the biggest blob (default: false, i.e. keep all blobs)
- `--half_precision`: run the model using half precision (float16) instead of full precision (float32) (default: false). This can speed up the inference on compatible GPUs and reduce memory usage, but may slightly reduce the accuracy of the parcellation. Use with caution.

Note: you will most likely have to have internet access when running for the first time to pull the code, docker containers and model weights.

See USAGE for more instructions on how to run the workflow. Have a question ? Found a problem ? Please open an issue or contact me at antoine (dot) theberge (at) usherbrooke (dot) ca.

## Bundles

Bundle defintions follow [TractSeg](https://github.com/MIC-DKFZ/TractSeg)'s, without the whole corpus callosum. However it is still represented in 7 subparts which should be coherent between their parcellations.

For completeness the bundle definitions are listed below

```
AF_left        (Arcuate fascicle)
AF_right
ATR_left       (Anterior Thalamic Radiation)
ATR_right
CA             (Commissure Anterior)
CC_1           (Rostrum)
CC_2           (Genu)
CC_3           (Rostral body (Premotor))
CC_4           (Anterior midbody (Primary Motor))
CC_5           (Posterior midbody (Primary Somatosensory))
CC_6           (Isthmus)
CC_7           (Splenium)
CG_left        (Cingulum left)
CG_right   
CST_left       (Corticospinal tract)
CST_right 
MLF_left       (Middle longitudinal fascicle)
MLF_right
FPT_left       (Fronto-pontine tract)
FPT_right 
FX_left        (Fornix)
FX_right
ICP_left       (Inferior cerebellar peduncle)
ICP_right 
IFO_left       (Inferior occipito-frontal fascicle) 
IFO_right
ILF_left       (Inferior longitudinal fascicle) 
ILF_right 
MCP            (Middle cerebellar peduncle)
OR_left        (Optic radiation) 
OR_right
POPT_left      (Parieto‐occipital pontine)
POPT_right 
SCP_left       (Superior cerebellar peduncle)
SCP_right 
SLF_I_left     (Superior longitudinal fascicle I)
SLF_I_right 
SLF_II_left    (Superior longitudinal fascicle II)
SLF_II_right
SLF_III_left   (Superior longitudinal fascicle III)
SLF_III_right 
STR_left       (Superior Thalamic Radiation)
STR_right 
UF_left        (Uncinate fascicle) 
UF_right 
T_PREF_left    (Thalamo-prefrontal)
T_PREF_right 
T_PREM_left    (Thalamo-premotor)
T_PREM_right 
T_PREC_left    (Thalamo-precentral)
T_PREC_right 
T_POSTC_left   (Thalamo-postcentral)
T_POSTC_right 
T_PAR_left     (Thalamo-parietal)
T_PAR_right 
T_OCC_left     (Thalamo-occipital)
T_OCC_right 
ST_FO_left     (Striato-fronto-orbital)
ST_FO_right 
ST_PREF_left   (Striato-prefrontal)
ST_PREF_right 
ST_PREM_left   (Striato-premotor)
ST_PREM_right 
ST_PREC_left   (Striato-precentral)
ST_PREC_right 
ST_POSTC_left  (Striato-postcentral)
ST_POSTC_right
ST_PAR_left    (Striato-parietal)
ST_PAR_right 
ST_OCC_left    (Striato-occipital)
ST_OCC_right
```

## To cite

Journal paper submitted. Please contact us for acknowledgement.
