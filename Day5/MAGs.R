library(tidyverse)


##### IMPORT DATA #####

# Create metadata
metadata <- tibble(Sample = c("Sample01", "Sample02", "Sample03", "Sample04"),
                   Ecosystem = c("heathland", "fen", "fen", "heathland"))

# Read bins summary
summary <- bind_rows(read_delim("Sample01.bins_summary.txt", delim = "\t"),
                     read_delim("Sample02.bins_summary.txt", delim = "\t"),
                     read_delim("Sample03.bins_summary.txt", delim = "\t"),
                     read_delim("Sample04.bins_summary.txt", delim = "\t"))

# Make a list of MAGs
MAGs <- summary %>%
  filter(str_detect(bins, "_MAG_")) %>%
  pull(bins)

# Read bins coverage
coverage <- bind_rows(read_delim("Sample01.mean_coverage.txt", delim = "\t"),
                      read_delim("Sample02.mean_coverage.txt", delim = "\t"),
                      read_delim("Sample03.mean_coverage.txt", delim = "\t"),
                      read_delim("Sample04.mean_coverage.txt", delim = "\t")) %>% 
  rename_all(~str_replace(., "SAMPLE", "Sample"))

# Read bins detection
detection <- bind_rows(read_delim("Sample01.detection.txt", delim = "\t"),
                       read_delim("Sample02.detection.txt", delim = "\t"),
                       read_delim("Sample03.detection.txt", delim = "\t"),
                       read_delim("Sample04.detection.txt", delim = "\t")) %>% 
  rename_all(~str_replace(., "SAMPLE", "Sample"))

# Read GTDB taxonomy
GTDB <- bind_rows(read_delim("gtdbtk.ar122.summary.tsv",  delim = "\t") %>% mutate(red_value = as.numeric(red_value)),
                  read_delim("gtdbtk.bac120.summary.tsv", delim = "\t") %>% mutate(red_value = as.numeric(red_value))) %>%
  separate(classification, into = c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species"), sep = ";") %>% 
  rename(bins = user_genome) %>%
  mutate(bins = str_remove(bins, "-contigs"))

# Read annotation
annotation <- bind_rows(read_delim("Sample01.gene_annotation.txt", delim = "\t") %>% mutate(Sample = "Sample01"),
                        read_delim("Sample02.gene_annotation.txt", delim = "\t") %>% mutate(Sample = "Sample02"),
                        read_delim("Sample03.gene_annotation.txt", delim = "\t") %>% mutate(Sample = "Sample03"),
                        read_delim("Sample04.gene_annotation.txt", delim = "\t") %>% mutate(Sample = "Sample04")) %>%
  rename(gene_function = `function`)

# Read list of gene calls per split
gene_calls <- bind_rows(read_delim("Sample01.genes_per_split.txt", delim = "|") %>% mutate(Sample = "Sample01"),
                        read_delim("Sample02.genes_per_split.txt", delim = "|") %>% mutate(Sample = "Sample02"),
                        read_delim("Sample03.genes_per_split.txt", delim = "|") %>% mutate(Sample = "Sample03"),
                        read_delim("Sample04.genes_per_split.txt", delim = "|") %>% mutate(Sample = "Sample04"))

# Read list of splits per bin
splits <- bind_rows(read_delim("Sample01.splits_per_bin.txt", delim = "|") %>% mutate(Sample = "Sample01"),
                    read_delim("Sample02.splits_per_bin.txt", delim = "|") %>% mutate(Sample = "Sample02"),
                    read_delim("Sample03.splits_per_bin.txt", delim = "|") %>% mutate(Sample = "Sample03"),
                    read_delim("Sample04.splits_per_bin.txt", delim = "|") %>% mutate(Sample = "Sample04")) %>% 
  select(-collection)


##### EXPLORING THE SUMMARY #####

# Number of bins/MAGs per sample
summary %>% 
  filter(bins %in% MAGs) %>% 
  mutate(Sample = str_extract(bins, "Sample[0-9]+")) %>% 
  group_by(Sample) %>% 
  tally

# MAG statistics
summary_long <- summary %>% 
  filter(bins %in% MAGs) %>% 
  select(total_length, percent_completion, percent_redundancy) %>% 
  gather(parameter, value)

## Summarise
summary_long %>% 
  group_by(parameter) %>% 
  summarise(mean = mean(value))

## Plot
summary_long %>% 
  ggplot(aes(x = parameter, y = value)) +
  geom_violin() +
  facet_wrap(~parameter, scales = "free")


##### GTDB TAXONOMY #####

# Summarise

## Phyla
GTDB_phylum <- GTDB %>% 
  group_by(Domain, Phylum) %>%
  tally

GTDB_phylum %>% 
  arrange(desc(n))

## Genera
GTDB_genus <- GTDB %>% 
  group_by(Phylum, Genus) %>%
  tally

GTDB_genus %>% 
  arrange(desc(n))

# Plot

## Phyla
GTDB_phylum %>% 
  ggplot(aes(x = Phylum, y = n)) +
  geom_bar(stat = "identity") +
  facet_grid(cols = vars(Domain), space = "free", scales = "free_x") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1), axis.title = element_blank())

## Genera
GTDB_genus %>% 
  ggplot(aes(x = Genus, y = n)) +
  geom_bar(stat = "identity") +
  facet_grid(cols = vars(Phylum), space = "free", scales = "free_x") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1), axis.title = element_blank())


##### COVERAGE & DETECTION #####

# Most abundant MAG across all samples
coverage_mean <- coverage %>% 
  gather(Sample, coverage, -bins) %>% 
  group_by(bins) %>% 
  summarise(mean = mean(coverage))

coverage_mean %>% 
  arrange(desc(mean)) %>% 
  left_join(GTDB) %>% 
  select(bins, Domain, Phylum, Class, Order, Family, Genus)

# Plot

## Coverage
coverage %>% 
  filter(bins %in% MAGs) %>%
  gather(Sample, coverage, -bins) %>% 
  left_join(metadata) %>% 
  left_join(GTDB) %>% 
  ggplot(aes(x = bins, y = coverage, fill = Ecosystem)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_grid(rows = vars(Sample), cols = vars(Domain, Phylum), scales = "free_x", space = "free") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5), axis.title = element_blank())

## Detection
detection %>% 
  filter(bins %in% MAGs) %>% 
  gather(Sample, detection, -bins) %>% 
  left_join(metadata) %>% 
  left_join(GTDB) %>% 
  ggplot(aes(x = bins, y = detection, fill = Ecosystem)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_grid(rows = vars(Sample), cols = vars(Domain, Phylum), scales = "free_x", space = "free") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5), axis.title = element_blank())


##### SEARCHING ANNOTATIONS #####

# Nitric oxide reductase
NOR <- annotation %>% 
  filter(str_detect(accession, "K04561") | str_detect(accession, "K02305")) %>% 
  left_join(gene_calls) %>% 
  left_join(splits)

NOR %>% 
  select(bins) %>% 
  mutate(MAG_or_BIN = ifelse(str_detect(bins, "Bin"), "bin", "MAG")) %>% 
  left_join(GTDB) %>% 
  group_by(MAG_or_BIN, Domain, Phylum) %>% 
  tally

# Nitrous oxide reductase
NOS <- annotation %>% 
  filter(str_detect(accession, "K00376")) %>% 
  left_join(gene_calls) %>% 
  left_join(splits)

NOS %>% 
  select(bins) %>% 
  mutate(MAG_or_BIN = ifelse(str_detect(bins, "Bin"), "bin", "MAG")) %>% 
  left_join(GTDB) %>% 
  group_by(MAG_or_BIN, Domain, Phylum) %>% 
  tally

# Nitrogenase
NIF <- annotation %>% 
  filter(str_detect(accession, "K02588")) %>% 
  left_join(gene_calls) %>% 
  left_join(splits)

NIF %>% 
  select(bins) %>% 
  mutate(MAG_or_BIN = ifelse(str_detect(bins, "Bin"), "bin", "MAG")) %>% 
  left_join(GTDB) %>% 
  group_by(MAG_or_BIN, Domain, Phylum) %>% 
  tally

# Methanogenesis
MCR <- annotation %>% 
  filter(str_detect(accession, "K00399")) %>% 
  left_join(gene_calls) %>% 
  left_join(splits)

MCR %>% 
  select(bins) %>% 
  mutate(MAG_or_BIN = ifelse(str_detect(bins, "Bin"), "bin", "MAG")) %>% 
  left_join(GTDB) %>% 
  group_by(MAG_or_BIN, Domain, Phylum) %>% 
  tally

# Methane oxidation
PMO <- annotation %>% 
  filter(str_detect(accession, "K10944")) %>% 
  left_join(gene_calls) %>% 
  left_join(splits)

PMO %>% 
  select(bins) %>% 
  mutate(MAG_or_BIN = ifelse(str_detect(bins, "Bin"), "bin", "MAG")) %>% 
  left_join(GTDB) %>% 
  group_by(MAG_or_BIN, Domain, Phylum) %>% 
  tally
