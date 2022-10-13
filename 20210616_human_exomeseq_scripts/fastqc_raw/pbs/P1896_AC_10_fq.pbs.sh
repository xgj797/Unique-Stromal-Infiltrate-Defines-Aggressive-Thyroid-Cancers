
cd '/scratch/weissvl/shengq2/20210616_human_exomeseq/fastqc_raw/result/P1896_AC_10'

set -o pipefail



rm -f P1896_AC_10.fastqc.failed

fastqc  --extract -t 2 -o `pwd` "/data/h_vivian_weiss/DNAseq/1896/1896-AC-10-CCGCGTATAG-GATCAAGGCA_S53_R1_001.fastq.gz" "/data/h_vivian_weiss/DNAseq/1896/1896-AC-10-CCGCGTATAG-GATCAAGGCA_S53_R2_001.fastq.gz" 2> >(tee P1896_AC_10.fastqc.stderr.log >&2)

status=$?
if [[ $status -ne 0 ]]; then
  touch P1896_AC_10.fastqc.failed
else
  touch P1896_AC_10.fastqc.succeed
fi

fastqc --version | cut -d ' ' -f2 | awk '{print "FastQC,"$1}' > `pwd`/fastqc.version