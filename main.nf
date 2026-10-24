#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.samplesheet = "${projectDir}/samplesheet.csv"
params.index = null
params.gtf = null
params.outdir = "results"
params.threads = 4
params.qvalue = 0.01

if (!params.index) error "Please provide --index"
if (!params.gtf) error "Please provide --gtf"

Channel
    .fromPath(params.samplesheet, checkIfExists: true)
    .splitCsv(header: true)
    .map { row ->
        tuple(
            row.sample.toString(),
            row.condition.toString(),
            file(row.fastq_1.toString(), checkIfExists: true),
            file(row.fastq_2.toString(), checkIfExists: true)
        )
    }
    .set { read_pairs }

workflow {
    gtf_ch = Channel.fromPath(params.gtf, checkIfExists: true)

    FASTQC(read_pairs)
    MULTIQC(FASTQC.out.html.collect())

    ALIGN_TOPHAT(read_pairs, gtf_ch)
    aligned_bams = ALIGN_TOPHAT.out.bam

    CUFFLINKS(aligned_bams, gtf_ch)
    CUFFDIFF(aligned_bams.collect(), gtf_ch)

    MAKE_DAVID_LIST(CUFFDIFF.out.diff, params.qvalue)
}

process FASTQC {
    tag "$sample"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample), val(condition), path(read1), path(read2)

    output:
    path "*_fastqc.html", emit: html
    path "*_fastqc.zip", emit: zip

    script:
    """
    fastqc --threads ${params.threads} ${read1} ${read2}
    """
}

process MULTIQC {
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path qc_reports

    output:
    path "multiqc_report.html"

    script:
    """
    multiqc . --force --filename multiqc_report.html
    """
}

process ALIGN_TOPHAT {
    tag "$sample"
    publishDir "${params.outdir}/tophat", mode: 'copy'

    input:
    tuple val(sample), val(condition), path(read1), path(read2)
    path gtf

    output:
    tuple val(sample), val(condition), path("${sample}.bam"), emit: bam

    script:
    """
    tophat -p ${params.threads} -G ${gtf} \
        -o ${sample} ${params.index} ${read1} ${read2}

    cp ${sample}/accepted_hits.bam ${sample}.bam
    """
}

process CUFFLINKS {
    tag "$sample"
    publishDir "${params.outdir}/cufflinks", mode: 'copy'

    input:
    tuple val(sample), val(condition), path(bam)
    path gtf

    output:
    path "${sample}/"

    script:
    """
    cufflinks -p ${params.threads} -g ${gtf} -o ${sample} ${bam}
    """
}

process CUFFDIFF {
    publishDir "${params.outdir}/cuffdiff", mode: 'copy'

    input:
    val alignments
    path gtf

    output:
    path "cuffdiff_out/gene_exp.diff", emit: diff

    script:
    def conditions = alignments.collect { it[1] }.unique()

    if (conditions.size() != 2) {
        error "Expected exactly two conditions"
    }

    def groups = conditions.collect { condition ->
        alignments.findAll { it[1] == condition }
            .collect { it[2].getName() }
            .join(',')
    }

    """
    cuffdiff -p ${params.threads} -o cuffdiff_out \
        ${gtf} '${groups[0]}' '${groups[1]}'
    """
}

process MAKE_DAVID_LIST {
    publishDir "${params.outdir}/david", mode: 'copy'

    input:
    path diff_file
    val qvalue

    output:
    path "david_gene_ids.txt"

    script:
    """
    awk -F '\\t' -v cutoff=${qvalue} '
    NR == 1 {
        for (i = 1; i <= NF; i++) col[$i] = i
        if (!col["gene_id"] || !col["q_value"]) exit 2
        next
    }
    $(col["q_value"]) != "-" &&
    $(col["q_value"]) != "nan" &&
    $(col["q_value"]) + 0 < cutoff &&
    $(col["gene_id"]) != "-" {
        print $(col["gene_id"])
    }
    ' ${diff_file} | sort -u > david_gene_ids.txt
    """
}
