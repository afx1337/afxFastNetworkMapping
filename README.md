# afxFastNetworkMapping

A fast MATLAB implementation for large-scale functional connectivity mapping using normative connectomes (compatible with Lead-DBS formats, tested with GSP1000 and dedicated afxNetworkMapping connectomes).

The tool is optimized for high-throughput analysis with hundreds to thousands of regions of interest (ROIs) and supports both whole-brain connectivity mapping and ROI-to-ROI connectivity analysis.

---

## Features

* Fast seed-to-whole-brain connectivity mapping
* Seed-to-target (ROI-to-ROI) connectivity analysis
* Supports multiple ROI definitions:
  * NIfTI masks (`image`)
  * Spherical ROIs (`sphere`)
  * Atlas-based ROIs (`atlas`)
* Efficient handling of large ROI sets (up to several thousands)
* Outputs:
  * Whole-brain NIfTI connectivity maps
  * ROI-to-ROI connectivity matrices
  * Metadata (`.mat` and `.json`)

---

## Requirements

* MATLAB (tested with R2017b and newer; likely compatible with older versions)
* No MATLAB toolboxes required
* not tested with GNU Octave
* Dependency:
  * SPM12 (https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)
* Connectome data (see below)

Tested on:

* Linux
* Windows

---

## Installation

Clone the repository and ensure the `scripts/` folder is on your MATLAB path:

```matlab
addpath('scripts');
```

---

## Connectome Data (Required)

This tool requires a compatible normative connectome. You can either use connectomes compiled for Lead-DBS (in *.mat format) or connectomes compiled specifically for afxFastNetworkMapping. Connectomes can be represented by prerpocessed BOLD timeseries or by low rank matrix approximations using (truncated) principal component analysis. A function for calculating low rank matrix approximations of connectomes can be found in the source code (```afxCompressConnectomeIndividual()```).

### GSP100

#### Download

Download the GSP1000 connectome dataset for Lead-DBS from: https://doi.org/10.7910/DVN/KKTJQC (203 GB)

#### Setup

1. Place the downloaded data in:

   ```
   connectomes/GSP1000/
   ```

2. Adjust and run the provided helper script:

   ```matlab
   connectomes/GSP1000/prepare.m
   ```

3. Use the file:

   ```matlab
   connectomes/GSP1000/dataset_info.mat
   ```

   as input to the pipeline.

> Note: The implementation is tested with GSP1000 but should work with other Lead-DBS compatible connectomes.

---

## Quick Start

```matlab
connectome = 'connectomes/GSP1000/dataset_info.mat';

rois(1).name = '10';
rois(1).type = 'image';
rois(1).file = '/path/10.nii';

rois(2).name = 'aIFG';
rois(2).type = 'sphere';
rois(2).coords = [-54 26 4];
rois(2).radius = 5;

options.gmMask = 'masks/gmmask_20_ext.nii';
options.compressNii = true;

destFolder = 'results/test1';

addpath('scripts');
afxFastNetworkMapping(connectome, rois, options, destFolder);
rmpath('scripts');
```

---

## Function Interface

```matlab
afxFastNetworkMapping(connectomeFile, rois, options, destFolder)
```

### Inputs

#### `connectomeFile`

Path to a compatible connectome (e.g. `dataset_info.mat`).

---

#### `rois`

Struct array describing regions of interest:

| Field  | Description                              |
| ------ | ---------------------------------------- |
| name   | Output filename                          |
| type   | `'image'`, `'sphere'`, or `'atlas'`      |
| file   | Path to NIfTI (for `image` or `atlas`)   |
| coords | MNI coordinates `[x y z]` (for `sphere`) |
| radius | Sphere radius in mm                      |
| pick   | Atlas label value                        |

---

#### `options`

| Field               | Description                                                         | Default |
| ------------------- | ------------------------------------------------------------------- | ------- |
| `gmMask`            | Optional gray matter mask applied to all ROIs                       | `[]`    |
| `compressNii`       | Save NIfTI files compressed *.nii.gz (`true/false`)                 | `false` |
| `targetRois`        | If set: compute ROI-to-ROI connectivity instead of whole-brain maps | `[]`    |
| `targetRoisMasking` | Apply gmMask to targetRois (`true/false`)                           | `true`  |
| `maxParticipants`   | Limit number of subjects (useful for testing)                       | `Inf`   |

**Notes:**

* If `targetRois` is provided, no whole-brain maps are generated.
* If `targetRois == rois`, the result is a square connectivity matrix.

---

#### `destFolder`

Output directory.

---

## Output

### Case 1: Whole-brain mapping

* One NIfTI file per ROI
* Each voxel contains:
  * Fisher z-transformed correlation coefficient
  * Averaged across all subjects

---

### Case 2: ROI-to-ROI connectivity

* `conn.mat` → connectivity matrix
* rows correspond to `options.targetRois`
* columns correspond to `rois`

---

### Additional outputs

* `info.mat` → MATLAB metadata
* `info.json` → human-readable metadata

Includes:

* ROI sizes (after gm masking)
* runtime
* configuration parameters

---

## Interpretation of Results

The output values represent:

* Fisher z-transformed correlation coefficients, i.e. functional connectivity
* Averaged across all subjects in the normative connectome

### Typical use cases

* Lesion Network Mapping (LNM)
* Deep Brain Stimulation (DBS) connectivity analyses

Example:

* If ROIs represent lesions → output corresponds to lesion network maps.

---

## Performance & Memory

### Runtime

* Native connectomes: **< 0.5 – 3 hours**
* Compressed connectomes: **< 5 – 30 minutes**
* Depends strongly on:
  * disk speed (SSD highly recommended)
  * CPU
  * number of ROIs
  * connectome

---

### Memory usage

Approximate RAM requirement (using GSP1000 connectome):

```
~300 MB base + 2.3 MB per ROI
```

| #ROIs  | RAM Usage |
| ------ | --------- |
| 50     | ~415 MB   |
| 250    | ~875 MB   |
| 500    | ~1.5 GB   |
| 1,000  | ~2.6 GB   |
| 5,000  | ~11.8 GB  |
| 10,000 | ~23.3 GB  |

---

### Notes

* CPU-only (no GPU support)
* No parallelization
* Disk I/O is often the bottleneck when using uncompressed connectomes (GSP1000 ≈ 200 GB)

---

## Notes on Connectomes

* Designed for Lead-DBS compatible or dedicated afxFastNetworkMapping connectomes
* Tested with GSP1000(https://doi.org/10.7910/DVN/KKTJQC)
* Other connectomes may work if they follow the same structure
* Supports connectomes represented in (tunrcated) PCA latent space
* For details on connectome structure, check the source code

---

## Documentation Note

Parts of this documentation were generated with the assistance of a large language model (LLM) and subsequently reviewed and adapted by the author.
