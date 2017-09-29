IndelTrim rewrites indels, where insertions are replaced with a single nucleotides and deletions stripped out, for the purpose of genotype phasing. 

IndelTrim is implemented in Haskell and supports VCF and Plink (bed,bim,fam) formats.

To install Haskell consider `sudo apt-get install cabal-platform`  .

To compile the script consider
```
  ghc indelTrim.hs -o indelTrim
```

To trim indels consider
```
  ./indelTrim trim -in file.vcf -hash file.hash -out file.trimmed.vcf
```

To untrim (restore) indels consider
```
  ./indelTrim untrim -in file.trimmed.vcf -hash file.hash -out file.untrimmed.vcf
```


The original indels are kept in a lookup table (denoted by command line swicth `-hash`), indexed by chromosome and position for later restoration.

Rebased insertions follow this mapping,
```
  A ~> C
  C ~> T
  T ~> G
  G ~> A
```

where the domain correponds to non-indel allele and the image corresponds to the nucleotide that replaces the indel.

For instance, given an insertion in `chr1` at position `123`, such as
```
  chr1 123 A ATT
```

the indel allele is replaced with `C` following the defined mapping above. This will create an entry in a lookup table such as 
```
  chr1 123 A ATT
```

Deletions are removed from the data file and chromosome, position and original alleles are added to the lookup table.  
