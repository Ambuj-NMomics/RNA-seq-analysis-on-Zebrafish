nextflow.enable.dsl=2

params.samplesheet = "${projectDir}/samplesheet.csv"
params.index       = null
params.gtf         = null
params.outdir      = "${projectDir}/results"
params.threads     = 4
params.qvalue      = 0.01


process FASTQC {
    tag "$sample"
    cpus 1

    input:
    tuple val(sample), val(condition), path(read1), path(read2)

    output:
    path "fastqc_out/*_fastqc.html", emit: html
    path "fastqc_out/*_fastqc.zip", emit: zip

    script:
    """
    mkdir -p fastqc_out
    fastqc --threads 1 --outdir fastqc_out "${read1}" "${read2}"
    """
}


process MULTIQC {
    tag "MultiQC"

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path html_reports
    path zip_reports

    output:
    path "multiqc_report.html", emit: report

    script:
    """
    multiqc . --force --filename multiqc_report.html
    """
}


process ALIGN_TOPHAT {
    tag "$sample"
    cpus params.threads

    publishDir "${params.outdir}/tophat", mode: 'copy'

    input:
    tuple val(sample), val(condition), path(read1), path(read2)
    path gtf

    output:
    tuple val(sample), val(condition), path("${sample}.bam"), emit: bam

    script:
    """
    tophat -p ${params.threads} -G "${gtf}" \
        -o "${sample}" "${params.index}" "${read1}" "${read2}"

    cp "${sample}/accepted_hits.bam" "${sample}.bam"
    """
}


process CUFFLINKS {
    tag "$sample"
    cpus params.threads

    publishDir "${params.outdir}/cufflinks", mode: 'copy'

    input:
    tuple val(sample), val(condition), path(bam)
    path gtf

    output:
    path "${sample}", emit: assembly

    script:
    """
    cufflinks -p ${params.threads} -g "${gtf}" \
        -o "${sample}" "${bam}"
    """
}


process CUFFDIFF {
    tag "Differential expression"
    cpus params.threads

    publishDir "${params.outdir}/cuffdiff", mode: 'copy'

    input:
    tuple val(samples), val(conditions), path(bams)
    path gtf

    output:
    path "cuffdiff_out/gene_exp.diff", emit: diff

    script:
    def conditionNames = conditions.unique()

    if (conditionNames.size() != 2) {
        error "Cuffdiff requires exactly two conditions; found: ${conditionNames}"
    }

    def groups = conditionNames.collect { condition ->
        (0..<conditions.size())
            .findAll { i -> conditions[i] == condition }
            .collect { i -> bams[i].getName() }
            .join(',')
    }

    """
    cuffdiff -p ${params.threads} -o cuffdiff_out \
        "${gtf}" "${groups[0]}" "${groups[1]}"
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
        for (i = 1; i <= NF; i++) col[\$i] = i
        if (!col["gene_id"] || !col["q_value"]) exit 2
        next
    }
    \$(col["q_value"]) != "-" &&
    \$(col["q_value"]) != "nan" &&
    \$(col["q_value"]) + 0 < cutoff &&
    \$(col["gene_id"]) != "-" {
        print \$(col["gene_id"])
    }
    ' "${diff_file}" | sort -u > david_gene_ids.txt
    """
}


workflow {
    if (!params.index) {
        error "Provide --index with the Bowtie 2 index prefix."
    }

    if (!params.gtf) {
        error "Provide --gtf with the annotation GTF file."
    }

    if (!file(params.gtf).exists()) {
        error "GTF file not found: ${params.gtf}"
    }

    def smallIndexExists =
        file("${params.index}.1.bt2").exists() &&
        file("${params.index}.2.bt2").exists() &&
        file("${params.index}.3.bt2").exists() &&
        file("${params.index}.4.bt2").exists() &&
        file("${params.index}.rev.1.bt2").exists() &&
        file("${params.index}.rev.2.bt2").exists()

    def largeIndexExists =
        file("${params.index}.1.bt2l").exists() &&
        file("${params.index}.2.bt2l").exists() &&
        file("${params.index}.3.bt2l").exists() &&
        file("${params.index}.4.bt2l").exists() &&
        file("${params.index}.rev.1.bt2l").exists() &&
        file("${params.index}.rev.2.bt2l").exists()

    if (!smallIndexExists && !largeIndexExists) {
        error "Bowtie 2 index not found for prefix: ${params.index}"
    }

    if (params.threads.toString().toInteger() < 1) {
        error "--threads must be at least 1"
    }

    def q = params.qvalue.toString().toDouble()
    if (q < 0.0d || q > 1.0d) {
        error "--qvalue must be between 0 and 1"
    }

    def samplesheet = file(params.samplesheet)
    if (!samplesheet.exists()) {
        error "Samplesheet not found: ${params.samplesheet}"
    }

    def reads = Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.sample || !row.condition ||
                !row.fastq_1 || !row.fastq_2) {
                error "Each samplesheet row needs sample, condition, fastq_1 and fastq_2."
            }

            tuple(
                row.sample.toString(),
                row.condition.toString(),
                file(row.fastq_1.toString(), checkIfExists: true),
                file(row.fastq_2.toString(), checkIfExists: true)
            )
        }

    def gtfCh = Channel.value(file(params.gtf))

    FASTQC(reads)

    MULTIQC(
        FASTQC.out.html.collect(),
        FASTQC.out.zip.collect()
    )

    ALIGN_TOPHAT(reads, gtfCh)

    CUFFLINKS(ALIGN_TOPHAT.out.bam, gtfCh)

    /*
     * Preserve each three-field alignment tuple during collection.
     * collect() defaults to flattening nested collections; flat:false
     * prevents the sample/condition/BAM records from being flattened.
     */
    def cuffdiffInput = ALIGN_TOPHAT.out.bam
        .collect(flat: false)
        .map { records ->
            def samples = []
            def conditions = []
            def bams = []

            records.each { record ->
                if (record.size() != 3) {
                    error "Expected (sample, condition, BAM); got: ${record.inspect()}"
                }

                samples << record[0]
                conditions << record[1]
                bams << record[2]
            }

            tuple(samples, conditions, bams)
        }

    CUFFDIFF(cuffdiffInput, gtfCh)

    MAKE_DAVID_LIST(CUFFDIFF.out.diff, params.qvalue)
}
