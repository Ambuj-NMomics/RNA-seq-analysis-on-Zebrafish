# RNA-seq Workflow: Results Summary

## 1. Run status

The Nextflow DSL2 workflow completed successfully for two paired-end zebrafish RNA-seq samples. All nine tasks succeeded.

## 2. Alignment quality

| Metric | 2-cell stage | 6-hour stage |
|---|---:|---:|
| Input reads per mate | 786,742 | 835,648 |
| Overall read mapping rate | 91.8% | 89.5% |
| Concordant pair alignment rate | 82.8% | 75.4% |
| Multiple alignments among aligned pairs | 5.5% | 11.5% |
| Discordant alignments | 1.1% | 4.8% |

The 6-hour sample had a lower concordant-pair alignment rate and higher multiple and discordant alignment rates. These differences warrant further investigation but do not, by themselves, establish that the sample is of poor quality.

## 3. Generated outputs

- FastQC quality-control reports
- MultiQC summary report
- TopHat aligned BAM files
- Cufflinks transcript assemblies and expression estimates
- Cuffdiff differential-expression table (`gene_exp.diff`)
- Candidate gene identifiers for potential DAVID analysis
- Nextflow execution report, timeline, and trace, when generated

Generated results are retained locally and are not committed to this repository.

## 4. Candidate gene list

The workflow generated four gene identifiers passing the configured q-value threshold of 0.01:

- `ENSDARG00000005185`
- `ENSDARG00000008697`
- `ENSDARG00000045067`
- `ENSDARG00000079092`

These are candidate identifiers selected by the workflow's filtering step. They should not be interpreted as independently validated biological discoveries.

## 5. Scientific limitations

Only one sample was available per condition. Biological variability cannot therefore be estimated reliably, and the differential-expression results are exploratory.

The dataset should not be used to make strong biological claims without additional independent biological replicates and an appropriate statistical analysis.

The DAVID preparation step extracts gene identifiers; it does not perform functional enrichment analysis itself.

## 6. Reproducibility notes

- Organism: *Danio rerio*
- Reference assembly: Zv9
- Annotation: `Danio_rerio.Zv9.66.gtf`
- Workflow engine: Nextflow DSL2
- Alignment and expression tools: TopHat, Cufflinks, and Cuffdiff
- Candidate-list q-value threshold: 0.01

Reference files and sequencing data must be obtained separately. Exact software versions, reference checksums, and input data provenance should be recorded to improve reproducibility.
