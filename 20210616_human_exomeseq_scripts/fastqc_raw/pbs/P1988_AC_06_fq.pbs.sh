
cd '/scratch/weissvl/shengq2/20210616_human_exomeseq/fastqc_raw/result/P1988_AC_06'

set -o pipefail



rm -f P1988_AC_06.fastqc.failed

fastqc  --extract -t 2 -o `pwd` "/data/h_vivian_weiss/DNAseq/1988/1988-AC-6-CGAGAGGCGT-ATTATGTCTC_S88_R1_001.fastq.gz" "/data/h_vivian_weiss/DNAseq/1988/1988-AC-6-CGAGAGGCGT-ATTATGTCTC_S88_R2_001.fastq.gz" 2> >(tee P1988_AC_06.fastqc.stderr.log >&2)

status=$?
if [[ $status -ne 0 ]]; then
  touch P1988_AC_06.fastqc.failed
else
  touch P1988_AC_06.fastqc.succeed
fi

fastqc --version | cut -d ' ' -f2 | awk '{print "FastQC,"$1}' > `pwd`/fastqc.version