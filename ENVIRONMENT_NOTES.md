# Environment and Reproducibility Notes

## Conda environment

The `environment.yml` file records the Conda environment used for the zebrafish RNA-seq workflow.

The environment includes:
- TopHat 2.1.1
- Bowtie 2.5.4
- Samtools 1.18
- Python 2.7.15

Python 2.7 is obsolete. This environment documents the legacy software used for the existing analysis and is not recommended for new production workflows.

## Tools installed outside Conda

The following tools were available from system-level or user-level installations:

- FastQC 0.12.1
- MultiQC 1.21
- Cufflinks 2.2.1
- Cuffdiff 2.2.1
- Nextflow 26.10.3
- OpenJDK 25.0.4.1

These tools are not fully captured by `environment.yml`. They must be installed separately at compatible versions to reproduce the workflow.

## Reference data

- Organism: Danio rerio
- Genome assembly: Zv9
- Annotation: `Danio_rerio.Zv9.66.gtf`
- Genome index prefix used in the test run: `ZV9`

Sequencing reads, reference FASTA, genome index files, and annotation files are external inputs and are not distributed in this repository.

## Reproducibility limitations

The exported Conda environment does not capture every system-level dependency, operating-system package, or reference-data checksum. Reproducing the original results may require additional setup and validation.
