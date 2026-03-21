#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process FASTQC {
    tag "FASTQC"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
        tuple val(sample), path(read1), path(read2)

    output:
        path "*.html"
        path "*.zip"

    script:
    """
    fastqc ${read1} ${read2}
    """
}


process TRIMMOMATIC {
    tag "TRIMMOMATIC"
    container "${projectDir}/trimmomatic.sif"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
        tuple val(sample), path(read1), path(read2)

    output:
        tuple path("${sample}_1_paired.fq.gz"),
              path("${sample}_2_paired.fq.gz")

    script: 
    """
    java -jar /opt/Trimmomatic-0.39/trimmomatic-0.39.jar PE -phred33 \
        ${read1} ${read2} \
        ${sample}_1_paired.fq.gz ${sample}_1_unpaired.fq.gz \
        ${sample}_2_paired.fq.gz ${sample}_2_unpaired.fq.gz \
        ILLUMINACLIP:/opt/Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:10 \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    """
}


process BWA_MEM {
    tag "BWA_MEM"
    publishDir "${params.outdir}/bwa", mode: 'copy'

    input:
        tuple path(r1), path(r2)
        path ref

    output:
        path "aligned.sam"

    script:
    """
    bwa index ${ref}
    bwa mem ${ref} ${r1} ${r2} > aligned.sam
    """
}

process SAMTOOLS_SORT {
    tag "SAMTOOLS"
    publishDir "${params.outdir}/bam", mode: 'copy'

    input:
        path sam

    output:
        path "sorted.bam"

    script:
    """
    samtools view -bS ${sam} | samtools sort -o sorted.bam
    """
}

process BCFTOOLS_CALL {
    tag "BCFTOOLS"
    publishDir "${params.outdir}/vcf", mode: 'copy'

    input:
        path bam
        path ref

    output:
        path "variants.vcf"

    script:
    """
    samtools index ${bam}
    bcftools mpileup -f ${ref} ${bam} | bcftools call -mv -Ov -o variants.vcf
    """
}

workflow {
    reads_ch = Channel.fromFilePairs(params.fastq, flat: true)
    ref_ch   = Channel.value(file(params.reference))

    fastqc_out = FASTQC(reads_ch)
    trimmed    = TRIMMOMATIC(reads_ch)
    aligned    = BWA_MEM(trimmed, ref_ch)
    bam_file   = SAMTOOLS_SORT(aligned)
    vcf_final  = BCFTOOLS_CALL(bam_file, ref_ch)

    println "Final VCF: ${params.outdir}/vcf/variants.vcf"
}
