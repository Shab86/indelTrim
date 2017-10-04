IndelTrim recodes indel alleles for the purpose of genotype phasing. 

IndelTrim is currently implemented in Scala and supports VCF format.

Download Scala from http://scala-lang.org/ .

To trim indels run
```
  ./trimVCF.sh file.vcf 
```
which will produce `file.vcf.trimmed.vcf` with trimmed indels and `file.vcf.hash` with original indels.

To untrim (restore) indels run
```
  cat file.vcf.trimmed.vcf | ./untrimVCF file.vcf.hash > file.untrimmed.vcf
```


The original indels are kept in a lookup table (denoted by command line switch `-hash`), indexed by chromosome and position for later restoration.

Rebased insertions follow this mapping,
```
  A ~> C
  C ~> T
  T ~> G
  G ~> A
```

where the domain correponds to non-indel allele and the image corresponds to the nucleotide that replaces the indel.

For instance, this insertion in `chr1` at position `123`
```
  chr1 123 A ATT
```
is kept verbatim in the hash file.
