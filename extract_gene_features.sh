
# add some flags and a help message and this will be almost done.

# at this stage we feed it:
#  gene name
#  ann file
#  ref
#  bam



# need to get this on github and workout how to best handle indels. My guess is the sensetivity is way too high

GENEACC="XM_011282361.3"
GENENAME=PKHD1_22055_1
ANN=~/Documents/ref_genomes/annotation/mammals/cat/felis_catus_9.0/Felis_catus_9.0_NCBI_UCSC_Predicted.gtf
BAM=~/mnt.wgs/bam/read_group_map/mapped_data/Fcat-22055-Chediak.sorted.markedDup.bam
REF=~/Documents/ref_genomes/fasta/mammals/cat/Felis_catus_9.0/Felis_catus_9.0.fa
STRAND="-"


tmp=$(date +%s%N)



# how to get gene of interest CDS
grep $GENEACC $ANN | grep exon | awk '{print $1"\t"$4-1"\t"$5}' > $tmp.bed

# extract range to trim bam file
RANGE=$(echo $(cut -f1 $tmp.bed | head -n1):$(sort $tmp.bed | cut -f2 | head -n1)-$(sort -r $tmp.bed | cut -f3 | head -n1))

# trim bam file
samtools view -@ 20 -hb $BAM $RANGE > $tmp.region.bam

bedtools intersect -abam $tmp.region.bam -b $tmp.bed > $tmp.bam

bcftools mpileup -Ou -q 60 -Q 30 -f $REF $tmp.bam | bcftools call -mv -Oz -o $tmp.calls.vcf.gz
tabix $tmp.calls.vcf.gz

cat $REF | bcftools consensus $tmp.calls.vcf.gz > $tmp.consensus.fa

bedtools getfasta -fi $tmp.consensus.fa -bed $tmp.bed -fo $tmp.gene.fa

grep -v ">" $tmp.gene.fa | tr -d '\n' | fold -w 50 > $tmp.con.cds.fa

echo ">"$GENENAME | cat - $tmp.con.cds.fa > $tmp.head.con.cds.fa

if [ $STRAND="-" ];
then
	seqkit seq -pr $tmp.head.con.cds.fa > $GENENAME.con.cds.fa
else
	mv $tmp.head.con.cds1.fa $GENENAME.con.cds.fa
fi

rm $tmp.*
