# Day 2

| Time      | Activity                       | Slides                               | Hands-on                                    |
|-----------|--------------------------------|--------------------------------------|---------------------------------------------|
| Morning   | Read-based analyses with MEGAN |                                      | [Link here](#MEGAN)                         |
| Afternoon | Read-based data analyses in R  |                                      | [Link here](#read-based-data-analysis-in-R) |

## MEGAN
We will start by checking if the script we ran yesterday finished successfully.  
Login to Puhti and go to your working directory, then:

- Take a look at the `READ_BASED_*_err.txt` and `READ_BASED_*_out.txt` files using `less`. Does it tell you something about the status of your script?
- Find the JOB ID number for each of your four jobs (you can find these in the name of the files you check just now).
- The use `seff JOBID` (changing `JOBID` of course) to see how your job went.
- Then see if you can find in your directory the folder `RESAMPLED`, `MEGAN` and `METAXA`.
- Are they empty? Do you see the ouput that was supposed to be produced by the commands?
- Now let's take a look for example the file `MEGAN/Sample01.megan.log.txt`. Does it seem that it finished correctly? What about the other three samples?


In the `MEGAN` directory, for each sample, you should find:
- `$SAMPLE.blastx.txt`: DIAMOND output
- `$SAMPLE.diamond.log.txt`: DIAMOND log
- `$SAMPLE.rma6`: MEGAN output
- `$SAMPLE.megan.log.txt`: MEGAN log

The `.rma6` files are compressed binary files created by `MEGAN` (command-line version).  
These describe the taxonomic and functional composition of the samples based on the `DIAMOND` annotation against the NCBI nr database.  

`MEGAN` also has a powerful GUI version, that you have installed in your own computer.  
First let's copy the four `.rma6` files to your own computers using FileZilla/scp/WinScp etc.  
When that's done let's launch `MEGAN` and take a look together at one of the samples.  

Now, by using the `Compare` tool, let's try to find differences between the samples.  
On the slides for the first day ("Course outline and practical info") we saw that we have two heathland and two fen soils.  
Can we see major differences in community structure between these two ecosystems? For example:
- Are samples from the same ecosystem type more similar to each other than to the other samples? **HINT:** Try changing the view to the Genus Rank and then going to "Window" > "Cluster Analysis" and chosing "UPGMA Tree".
- What is the most abundant phylum in the heathland soils? And in the fen soils?
- By the way, what is the main environmental difference between these two ecosystems? Can you think about how this could explain the difference in phylum abundance?
- Now looking at the functional profiles (e.g. SEED), can you spot differences between these two ecosystems? Specially regarding energy and metabolism?
- Again, how these differences relate to the environmental aspects of these ecosystems?

## Read based data analysis in R

### METAXA
Now we will work on the output of `METAXA`, the other tool we have employed to obtain taxonomic profiles for the communities.  
Metaxa2 outputs lot of files but at this point we only need the ones ending with `level_6.txt` and `level_7.txt`. They contain the genus and species level counts for each sammple.  
We will use Metaxa2 data collector tool to combine all of these reports to an abundance tables that we will read into R for further analyses.

```bash
export PROJAPPL=/projappl/project_2001499
module load bioconda/3
source activate metaxa

cd /scratch/project_2001499/$USER

metaxa2_dc -o METAXA/metaxa_genus.txt METAXA/*level_6.txt
metaxa2_dc -o METAXA/metaxa_species.txt METAXA/*level_7.txt
```

Then copy the two files to your own computer using `scp`, `WinSCP`, `FileZilla` or `Cyberduck`.
When the files have been copied, let's start `R/RStudio` and load the necessary packages:

```r
library(tidyverse)
library(phyloseq)
library(vegan)
library(DESeq2)
library(patchwork)
```

And let's change the directory the `READ_BASED_R` folder:

```r
setwd("PUT-HERE-TO-THE-PATH-TO-THE-READ-BASED-R-FOLDER")
```

#### Data import

```r
# Read metadata
metadata <- read.table("sample_info.txt", sep = "\t", row.names = 1, header = TRUE)

# Read METAXA results at the genus level
metaxa_genus <- read.table("metaxa_genus.txt", sep = "\t", header = TRUE, row.names = 1)

# Make taxonomy data frame
metaxa_TAX <- data.frame(Taxa = row.names(metaxa_genus)) %>%
  separate(Taxa, into = c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus"), sep = ";")

row.names(metaxa_genus) <- paste0("OTU", seq(nrow(metaxa_genus)))
row.names(metaxa_TAX) <- paste0("OTU", seq(nrow(metaxa_genus)))

# Make a phyloseq object
metaxa_genus <- phyloseq(otu_table(metaxa_genus, taxa_are_rows = TRUE),
                        tax_table(as.matrix(metaxa_TAX)),
                        sample_data(metadata))
```

#### Data exploration

```r
# Take a look at the phyloseq object
metaxa_genus

# See the first few OTUs
metaxa_genus %>% otu_table() %>% head
metaxa_genus %>% tax_table() %>%  head

# Take a look at the samples
metaxa_genus %>% sample_data()
metaxa_genus %>% sample_sums()

# Calculate the count per sample and plot it
metaxa_genus %>% sample_sums() %>% barplot()

# See the top 10 OTUs (most abundant throughout all samples)
metaxa_abund <- taxa_sums(metaxa_genus) %>%
  sort(decreasing = TRUE) %>%
  head(10) %>%
  names()

# See taxonomy for these OTUs
tax_table(metaxa_genus)[metaxa_abund,]

# And their abundance in our samples
otu_table(metaxa_genus)[metaxa_abund,]
```

#### Heatmap of the most abundant taxa

```r
metaxa_top10 <- prune_taxa(metaxa_abund, metaxa_genus)
otu_table(metaxa_top10) %>%  as.matrix() %>% sqrt() %>% t() %>% heatmap(col = rev(heat.colors(20)))

tax_table(metaxa_top10)[rownames(otu_table(metaxa_top10)), ]
```

#### Alpha diversity

```r
# Calculate and plot Shannon diversity
metaxa_genus %>% otu_table() %>% t() %>% diversity(index = "shannon") %>% barplot(ylab = "Shannon diversity")


# Calculate and plot richness
metaxa_genus %>% otu_table() %>% t() %>% specnumber() %>% barplot(ylab = "Observed taxa", las = 3)
```

#### Beta diversity

```r
# Calculate distance matrix and do ordination  
metaxa_ord_df <- metaxa_genus %>%
                    otu_table() %>%
                    t() %>%
                    vegdist() %>%
                    cmdscale() %>%
                    data.frame(Ecosystem = sample_data(metaxa_genus)$Ecosystem)

# Plot ordination
ggplot(metaxa_ord_df, aes(x = X1, y = X2, color = Ecosystem)) +
  geom_point(size = 3) +
  scale_color_manual(values=c("firebrick", "royalblue")) +
  theme_classic() +
  labs(x = "Axis-1", y = "Axis-2") +
  geom_text(label = row.names(metaxa_ord_df), nudge_y = 0.03) +
  theme(legend.position = "bottom")

# Test if differences are significant
adonis(metaxa_ord ~ Ecosystem, metadata)
```

#### Differential abundance analysis

```r
# Remove eukaryotes
metaxa_genus_noeuk <- subset_taxa(metaxa_genus, Kingdom == "Bacteria" | Kingdom == "Archaea")

# Run deseq
metaxa_deseq <- phyloseq_to_deseq2(metaxa_genus_noeuk, ~ Ecosystem)
metaxa_deseq <- DESeq(metaxa_deseq, test = "Wald", fitType = "local")

# Get deseq results
metaxa_deseq_res <- results(metaxa_deseq, cooksCutoff = FALSE)

# Keep only p < 0.01
metaxa_deseq_sig <- metaxa_deseq_res[which(metaxa_deseq_res$padj < 0.01), ]
metaxa_deseq_sig <- cbind(as(metaxa_deseq_sig, "data.frame"), as(tax_table(metaxa_genus_noeuk)[rownames(metaxa_deseq_sig), ], "matrix"))

### Plot differentially abundanta taxa
left_join(otu_table(metaxa_genus_noeuk) %>% as.data.frame %>% rownames_to_column("OTU"),
          metaxa_TAX %>% rownames_to_column("OTU")) %>%
  filter(OTU %in% rownames(metaxa_deseq_sig)) %>%
  unite(taxonomy, c(OTU, Kingdom, Phylum, Class, Order, Family, Genus), sep = "; ") %>%
  gather(Library, Reads, -taxonomy) %>%
  left_join(metadata %>% rownames_to_column("Library")) %>%
  mutate(Reads = sqrt(Reads)) %>%
  ggplot(aes(x = Library, y = taxonomy, fill = Reads)) +
  geom_tile() +
  facet_grid(cols = vars(Ecosystem), scale = "free") +
  scale_fill_gradient(low = "white", high = "skyblue4", name = "Reads (square root)") +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0))
```

### MEGAN

Let's also look at the data we exported from `MEGAN` using R.  
After importing the data as shown below, repeat the steps you have done for the `METAXA` data, this time using as input the `megan_genus`, `megan_COG`, and `MEGAN_SEED` objects.  

#### Data import

```r
# Read MEGAN results at the genus level
megan_genus <- import_biom("MEGAN_genus.biom")
sample_data(megan_genus) <- sample_data(metadata)

# Read COG functions
megan_COG <- import_biom("MEGAN_EGGNOG.biom")
sample_data(megan_COG) <- sample_data(metadata)

# Read SEED functions
megan_SEED <- import_biom("MEGAN_SEED.biom")
sample_data(megan_SEED) <- sample_data(metadata)
```
