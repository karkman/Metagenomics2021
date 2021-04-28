# Day 5

| Time      | Activity                                        | Slides                                                  | Hands-on                                                    |
|-----------|-------------------------------------------------|---------------------------------------------------------|-------------------------------------------------------------|
| Morning   | MAG annotation and downstream analyses (Part 1) | [Link here](MAG-annotation-and-downstream-analyses.pdf) | [Link here](#MAG-annotation-and-downstream-analyses-part-1) |
| Afternoon | MAG annotation and downstream analyses (Part 2) |                                                         | [Link here](#MAG-annotation-and-downstream-analyses-part-2) |
| Afternoon | Closing remarks and open discussion             |                                                         |                                                             |

## MAG annotation and downstream analyses (Part 1)
First login to Puhti and go to your working directory:

```bash
cd /scratch/project_2001499/$USER
```

Although you have probably binned some nice MAGs, we will work from now on with MAGs that Antti and Igor have binned.
Let's copy these to your working directory:

```bash
cp -r ../COURSE_FILES/MAGs MAGs
```

### MAG dereplication with dRep
Because we running individual assemblies, it could be that we have obtained a given MAG more than once.  
To remove this redundancy, we perform a step that is called dereplication.  
Here we will use `dRep` for this (to learn more about `dRep` see [here](https://drep.readthedocs.io/)):

```bash
sinteractive -A project_2001499 -c 4

export PROJAPPL=/projappl/project_2001499
module load bioconda/3
source activate drep

dRep compare DREP \
             --genomes MAGs/*.fa \
             --processors 4
```

Copy the `DREP` folder to your computer and look at the PDF files inside the `figures` folder, particularly the primary and secondary clustering dendrograms.  
Also look at the `Cdb.csv` file inside `data_tables`.  
How many clusters of duplicated (redudant) MAGs do we have?

### Taxonomic assignment with GTDBtk
Normally, one thing that we want to learn more about is the taxonomy of our MAGs.  
Although `anvi'o` gives us a preliminary idea, we can use a more dedicated platform for taxonomic assignment of MAGs.  
Here we will use `GTDBtk`, a tool to infer taxonomy for MAGs based on the GTDB database (you can - and probably should - read more about GTDB [here](https://gtdb.ecogenomic.org/)).  

We have prepared a script to run `GTDBtk` for you, so let's copy it and take a look:

```bash
cp ../COURSE_FILES/SBATCH_SCRIPTS/GTDBtk.sh .
```

And submit the script using `sbatch`.





# THIS IS OLD; CHECK


Let's copy the two summary files:

```bash
cp ~/Share/GTDB/gtdbtk.bac120.summary.tsv MAGs
cp ~/Share/GTDB/gtdbtk.ar122.summary.tsv MAGs
```

I particularly am curious about `Sample03Short_MAG_00001`, the nice bin from yesterday that had no taxonomic assignment.  
I wonder if it's an archaeon?

```bash
grep Sample03Short_MAG_00001 MAGs/gtdbtk.ar122.summary.tsv
```

It doesn't look like it, no...  
Let's see then in the bacterial classification summary:

```bash
grep Sample03Short_MAG_00001 MAGs/gtdbtk.bac120.summary.tsv
```

And what other taxa we have?  
Let's take a quick look with some `bash` magic:

```bash
cut -f 2 gtdbtk.bac120.summary.tsv | sed '1d' | sort | uniq -c | sort
```

Later on, let's see if we can do some more analyses on R.

### Functional annotation
Let's now annotate the MAGs against databases of functional genes to try to get an idea of their metabolic potential.  
As everything else, there are many ways we can annotate our MAGs.  
Here, let's take advantage of `anvi'o` for this as well.  
Annotation usually takes some time to run, so we won't do it here.  
But let's take a look below at how you could achieve this:

```bash
conda activate anvio-7

for SAMPLE in Sample01 Sample02 Sample03 Sample04; do
  anvi-run-ncbi-cogs --contigs-db $SAMPLE/CONTIGS.db \
                     --num-threads 4

  anvi-run-kegg-kofams --contigs-db $SAMPLE/CONTIGS.db \
                       --num-threads 4

  anvi-run-pfams --contigs-db $SAMPLE/CONTIGS.db \
                 --num-threads 4
done
```

These steps have been done by us already, and the annotations have been stored inside the `CONTIGS.db` of each assembly.  
What we need now is to get our hands on a nice table that we can then later import to R.  
We can achieve this by running `anvi-export-functions`:

```bash
for SAMPLE in Sample01 Sample02 Sample03 Sample04; do
  anvi-export-functions --contigs-db ~/Share/BINNING_MEGAHIT/$SAMPLE/CONTIGS.db \
                        --output-file MAGs/$SAMPLE.gene_annotation.txt
done
```

Since we're at it, let's also recover the information about i) the genes found in each split and ii) which splits belong to wihch bin/MAG.  
I don't think there's a straightforward way to get this using `anvi'o` commands, but because `CONTIGS.db` and `PROFILES.db` are [SQL](https://en.wikipedia.org/wiki/SQL) databases, we can access information within them using `sqlite3`:

```bash
for SAMPLE in Sample01 Sample02 Sample03 Sample04; do
  # Get list of gene calls per split
  printf '%s|%s|%s|%s|%s\n' splits gene_callers_id start stop percentage > MAGs/$SAMPLE.genes_per_split.txt
  sqlite3 ~/Share/BINNING_MEGAHIT/$SAMPLE/CONTIGS.db 'SELECT * FROM genes_in_splits' >> MAGs/$SAMPLE.genes_per_split.txt


  # Get splits per bin
  printf '%s|%s|%s\n' collection splits bins > MAGs/$SAMPLE.splits_per_bin.txt
  sqlite3 ~/Share/BINNING_MEGAHIT/$SAMPLE/MERGED_PROFILES/PROFILE.db 'SELECT * FROM collections_of_splits' | grep 'MAGs|' >> MAGs/$SAMPLE.splits_per_bin.txt
done
```

## MAG annotation and downstream analyses (Part 2)

Now let's get all these data into R to explore the MAGs taxonomic identity and functional potential.  
First, download the `MAGs` folder to your computer using FileZilla.
