WORKFLOW PIPELINE

This repository contains a reproducible workflow for the whoe genome sequence(WGS)

## Contents
- main.nf - Nextflow pipeline script
- nextflow.config - Configuration file for Nextflow
- trimmomatic.def - Singularity definiton for Trimmomatic
- variants.db - SQLite database containg variant information
- README.md - This file
## Container
The trimmomatic container was built using singularity definition file 'trimmomatic.def' .
To build the container:

singularity build --fakeroot trimmomatic.sif trimmomatic.def  

## Workflow 

1. **Quality Control**: FASTQC is run on raw reads.
2. **Trimming**: Trimmomatic removes adapters and low quality bases.
3. **Alignment**: Reads are aligned to the reference genome using BWA.
4. **Sorting**: SAM files are converted to BAM and sorted with SAMTOOLS.
5. **Variant Caling**: Variants are called using BCFTOOLS  and sorted in ' variants.vcf'

## Usage
Run the workflow using Nextflow with the provided configuration and reference files.

## Troubleshooting
-Ensure that all required modules are loaded
