# Zebrafish RNA-seq Analysis Workflow Using Nextflow

A reproducible bioinformatics workflow for paired-end RNA-seq analysis of *Danio rerio* developmental samples using Nextflow, TopHat, Cufflinks, Cuffdiff, FastQC, and MultiQC.

## Overview

This project implements an end-to-end RNA-seq workflow to process two zebrafish developmental samples:

- **2-cell stage**
- **6-hour stage (6h)**

The pipeline performs read quality control, splice-aware alignment, transcript assembly and abundance estimation, differential-expression analysis, and extraction of candidate gene identifiers for downstream enrichment analysis.

The workflow is orchestrated with Nextflow DSL2.

## Workflow

1. **FastQC** — evaluates the quality of paired-end sequencing reads.
2. **MultiQC** — aggregates quality-control reports.
3. **TopHat** — aligns reads to the zebrafish reference genome.
4. **Cufflinks** — assembles transcripts and estimates expression abundance.
5. **Cuffdiff** — compares expression between the two conditions.
6. **DAVID gene-list preparation** — extracts unique gene identifiers passing the configured q-value threshold for potential downstream functional analysis.

## Requirements

Install and configure the following tools:

- Nextflow
- Java runtime compatible with your Nextflow installation
- FastQC
- MultiQC
- TopHat 2
- Cufflinks and Cuffdiff
- Bowtie 2
- Samtools

The workflow was tested locally in a Linux environment. Exact versions and dependencies may affect reproducibility; use compatible versions of the legacy tools.

## Input data

### Paired-end FASTQ files

The samplesheet is `samplesheet.csv`:

```csv
sample,condition,fastq_1,fastq_2
2cells,2cells,../RNA/data/2cells_1.fastq,../RNA/data/2cells_2.fastq
6h,6h,../RNA/data/6h_1.fastq,../RNA/data/6h_2.fastq
```

Update the FASTQ paths to match your local environment. Paths are resolved relative to the workflow execution context, so verify them before running.

### Reference genome and annotation

The original analysis used:

- Reference genome: *Danio rerio*, Zv9
- Genome index prefix: `ZV9`
- Annotation: `Danio_rerio.Zv9.66.gtf`

The reference FASTA, Bowtie 2 index, and GTF annotation are external inputs and are not included in this repository.

**Important:** The genome assembly and annotation must be compatible with each other and with the aligner index.

## Running the workflow

Clone the repository:

```bash
git clone https://github.com/Ambuj-NMomics/zebrafish-rnaseq-workflow-clean.git
cd zebrafish-rnaseq-workflow-clean
```

Ensure that the FASTQ paths in `samplesheet.csv` exist and that the reference index and GTF are available.

Run the workflow:

```bash
nextflow run main.nf \
  --samplesheet "$PWD/samplesheet.csv" \
  --index "/path/to/reference/ZV9" \
  --gtf "/path/to/annotation/Danio_rerio.Zv9.66.gtf" \
  --outdir "$PWD/results" \
  --threads 4 \
  --qvalue 0.01
```

Replace the example reference paths with the paths on your system.

To preview the workflow without executing the analysis, add `-preview` to the command.

## Expected outputs

The workflow generates outputs under the chosen output directory.

| Directory or file | Description |
|---|---|
| `multiqc/multiqc_report.html` | Aggregated quality-control report |
| `tophat/` | Aligned BAM files |
| `cufflinks/` | Transcript assemblies and expression estimates |
| `cuffdiff/cuffdiff_out/gene_exp.diff` | Differential-expression results |
| `david/david_gene_ids.txt` | Unique gene IDs passing the configured q-value filter |
| `pipeline_report.html` | Nextflow execution report, when generated |
| `pipeline_timeline.html` | Task execution timeline, when generated |
| `pipeline_trace.txt` | Task-level execution trace, when generated |

Nextflow's `work/` directory contains task intermediates and logs. These files are useful for debugging but generally should not be committed to GitHub.

## Results from the test run

The workflow completed successfully for both samples, with all nine tasks succeeding.

| Alignment metric | 2-cell | 6h |
|---|---:|---:|
| Overall read mapping rate | 91.8% | 89.5% |
| Concordant pair alignment rate | 82.8% | 75.4% |
| Multiple alignments among aligned pairs | 5.5% | 11.5% |
| Discordant alignments | 1.1% | 4.8% |

The 6h sample had lower concordant-pair alignment and higher multiple and discordant alignment rates. These differences warrant further investigation and should not automatically be interpreted as poor sample quality.

The test run produced four gene identifiers passing the configured q-value filter. These are candidate results from this dataset, not independently validated discoveries.

## Important scientific limitations

This dataset contains **one sample per condition**. Consequently, biological variability cannot be estimated reliably, and differential-expression findings should be considered exploratory.

A stronger biological study should include independent biological replicates for each condition and use a statistical framework appropriate for replicated RNA-seq data.

TopHat, Cufflinks, and Cuffdiff are legacy tools. For a new production analysis, consider a maintained splice-aware aligner such as HISAT2 or STAR, gene-level quantification, and a replicated differential-expression workflow using DESeq2 or edgeR.

The DAVID gene-list preparation step only extracts identifiers; it does not itself perform functional enrichment analysis.

## Repository structure

```text
zebrafish-rnaseq-workflow-clean/
├── main.nf
├── nextflow.config
├── samplesheet.csv
├── .gitignore
└── README.md
```

## Reproducibility

- Workflow orchestration: Nextflow DSL2
- Organism: *Danio rerio*
- Reference assembly: Zv9
- Input type: paired-end FASTQ
- Differential-expression output: Cuffdiff `gene_exp.diff`
- Candidate gene-list threshold: q-value < 0.01 by default

For exact reproducibility, record tool versions, reference checksums, the original sequencing-data source, and the precise workflow parameters used.

## License

No license is specified yet. Add a license before permitting others to reuse or redistribute the code.

## Author

**Ambuj Narayan Maurya**

Bioinformatics | RNA-seq | Nextflow | Genomics

