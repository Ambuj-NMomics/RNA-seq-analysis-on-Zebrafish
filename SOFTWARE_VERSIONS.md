# Software Versions

Software versions recorded from the local zebrafish RNA-seq workflow environment.

| Tool | Version | Role |
|---|---|---|
| Nextflow | 26.10.3 | Workflow orchestration |
| Java | OpenJDK 25.0.4.1 | Runtime for Nextflow |
| FastQC | 0.12.1 | Raw-read quality control |
| MultiQC | 1.21 | Aggregation of QC reports |
| TopHat | 2.1.1 | Splice-aware read alignment |
| Cufflinks | 2.2.1 | Transcript assembly and expression estimation |
| Cuffdiff | 2.2.1 | Differential-expression comparison |
| Samtools | 1.18 | BAM inspection and validation |
| Bowtie 2 | 2.5.4 | Alignment backend/index compatibility |

## Reference data

- Organism: *Danio rerio*
- Genome assembly: Zv9
- Annotation: `Danio_rerio.Zv9.66.gtf`
- Genome index prefix used in the test run: `ZV9`

Reference FASTA, index files, annotation, and sequencing reads are external inputs and are not distributed in this repository.

## Environment notes

These versions were observed in the local Linux environment used for the workflow. Availability and compatibility may differ on other systems.

TopHat, Cufflinks, and Cuffdiff are legacy tools. This file records the environment used for the existing analysis; it does not imply that these tools are recommended for new production RNA-seq studies.

The exact package build strings, installation channels, and versions of all transitive dependencies have not yet been captured.
