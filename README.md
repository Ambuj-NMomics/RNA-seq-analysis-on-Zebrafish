# Zebrafish RNA-seq Analysis with Nextflow

## Overview

This project documents an RNA-seq comparison of zebrafish embryos
at the 2-cell stage and 6 hours post-fertilization (6 hpf).

## Workflow

1. FastQC quality control
2. MultiQC report aggregation
3. TopHat read alignment
4. Cufflinks transcript quantification
5. Cuffdiff differential expression
6. Gene-list preparation for DAVID functional enrichment

## Requirements

Nextflow, FastQC, MultiQC, TopHat, Bowtie, Cufflinks, Cuffdiff,
a compatible reference genome index, and its GTF annotation.

## Important limitation

The original comparison has one library per condition.
Differential-expression findings are exploratory, not validated
statistical evidence.

DAVID enrichment is a separate manual step. This pipeline prepares
a gene list but does not automatically submit it to DAVID.
