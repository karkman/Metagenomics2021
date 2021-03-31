*Antti Karkman, Igor S Pessi and Jenni Hultman*

# Metagenome analysis tundra soil metagenomes
Log into Puhti, either with ssh (Mac/Linux) or PuTTy (Windows)

__All the scripts are to be run in `your_name` folder!__

## Data download
First set up the your directory where you wil perform all the tasks for this course and create some folders. All the task are performed at Puhti scratch-folder in the course directory `project_2001499`.

mkdir $USER
cd $USER
mkdir TRIMMED

Check with `ls` what kind of folders were created. What kind of folder did the `mkdir $USER ` create?

```
## QC and trimming
QC for the raw data (takes few min, depending on the allocation). Go to your own folder under project_2001499 and make a folder called e.g. `FASTQC` for the QC reports.  

Can be done on the interactive nodes using `sinteractive`.   

# activate the biokit environment
module load biokit

# Run fastqc
fastqc ./*.fastq.gz -o FASTQC/

# Then combine the reports with multiqc ARE WE DOING THIS? OR SKIP?
multiqc ./ --interactive

```

Copy the resulting HTML file to your local machine with `scp` from the command line (Mac/Linux) or *WinSCP* on Windows. Have a look at the QC report with your favourite browser.  

After inspecting the output, it should be clear that we need to do some trimming.  
__What kind of trimming do you think should be done?__

For trimming we have a array script that runs `cutadapt` for each file in the `RAWDATA`folder located at `/scratch/project_2001499`.    
Go to your folder folder and copy the array script from `/scratch/project_2001499/SBATCH_SCRIPTS`. Check the script for exmaple with command `less`. The adapter sequences that you want to trim after `-a` and `-A`. What is the difference with `-a` and `-A`? And what is specified with option `-p` or `-o`? And how about `-m`and `-j`? You can find the answers from Cutadapt [manual](http://cutadapt.readthedocs.io).

Then we need to submit our jos to the SLURM system. Make sure to submit it from your own folder. More about CSC batch jobs here: https://research.csc.fi/taito-batch-jobs.  

`sbatch scripts/cut_batch.sh`  

You can check the status of your job with:  

`squeue -l -u $USER`  

After the job has finished, you can see how much resources it actually used and how many billing units were consumed. `JOBID` is the number after the batch job error and output files.  

`seff JOBID`  

Then let's check the results from the trimming.

Go to the folder containing the trimmed reads (`TRIMMED`) and make a new folder (`FASTQC`) for the QC files.  
Run FASTQC and MultiQC again.  

```

# run QC on the trimmed reads
fastqc ./*.fastq -o FASTQC/ -t 4
multiqc ./ --interactive

```
Copy it to your local machine as earlier and look how well the trimming went.  

## Assembly
We will assemble all 4 samples indivially and use [Megahit assembler](https://github.com/voutcn/megahit) for the job. *In addition, we will use MetaQuast to get some statistics about our assembly.  *

Megahit is an ultra fast assembly tool for metagenomics data. It is installed to CSC and be loaded with following command:

```
module load biokit
```

Assembling metagenomic data can be very resource demanding and we need to do it as a batch job. 

Copy the  script called MEGAHIT.sh from the SBATCH folder to your own directory and submit the batch job as previously.

What do the following flags mean?

--min-contig-len 1000
--k-min 27 
--k-max 127 
--k-step 10 
--memory 0.8 
--num-cpu-threads 8

## Read based analysis
We will annotate short reads with tool called Megan (ref) against NCBInr database. This will take a while and therefore will run it already today to have the results waiting on Tuesday. Megan utilizes program called Diamond (ref) which is a fast.....MORE

Since the four samples have been sequenced really deep, we will utilize only subset of them for read based analysis. The subsampled 2 000 000 sequences represent the total community for this analysis. Tool Seqtk is used for this and running seqtk in implemented in the MEGAN.sh script you can find from the same location as before. 

First, a folder called MEGAN to your own folder. 

Then copy MEGAN.sh to your folder. How can you check in which folder you are?

```
/scratch/project_2001499/SBATCH_SCRIPTS/MEGAN.sh

```
Launch Megan as you did for Cutadapt earlier today. We will annotate short reads with tool Diamond (ref) against NCBInr database. This will take a while and therefore will run it already todat to have the results waiting on Tuesday. 


***Jenni note, raw data for seqtk?****

For annotation copy script nnnn for Diamond. The database NCBInr is somethign CSC updates so we do not need to copy it ourselves. The databases found at CSC can be listed with command xxx in Puhti. 


# Optional

## (Fairly) Fast MinHash signatures with Sourmash

Go to the documentation of Sourmash and learn more about minhashes and the usage of Sourmash. https://sourmash.readthedocs.io/en/latest/

Before you start, make sure you're working at Taito-shell with command `sinteractive`.
```
sourmash compute *R1_trimmed.fastq -k 31 --scaled 10000
sourmash compare *.sig -o comparisons
sourmash plot comparisons
# annotate one
sourmash gather 09069-B_R1_trimmed.fastq.sig /wrk/antkark/shared/genbank-d2-k31.sbt.json -o OUTPUT_sour.txt
```

## Taxonomic profiling with Metaxa2

The microbial community profiling for the samples can alsp be done using a 16S/18S rRNA gene based classification software [Metaxa2](http://microbiology.se/software/metaxa2/).  
It identifies the 16S/18S rRNA genes from the short reads using HMM models and then annotates them using BLAST and a reference database.
We will run Metaxa2 as an array job in Taito. More about array jobs at CSC [here](https://research.csc.fi/taito-array-jobs).  
Make a folder for Metaxa2 results and direct the results to that folder in your array job script. (Takes ~6 h for the largest files)

```
#!/bin/bash -l
#SBATCH -J metaxa
#SBATCH -o metaxa_out_%A_%a.txt
#SBATCH -e metaxa_err_%A_%a.txt
#SBATCH -t 10:00:00
#SBATCH --mem=15000
#SBATCH --array=1-10
#SBATCH -n 1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=6
#SBATCH -p serial

cd $WRKDIR/Metagenomics2019/Metaxa2
# Metaxa uses HMMER3 and BLAST, so load the biokit first
module load biokit
# each job will get one sample from the sample names file stored to a variable $name
name=$(sed -n "$SLURM_ARRAY_TASK_ID"p ../sample_names.txt)
# then the variable is used in running metaxa2
metaxa2 -1 ../trimmed_data/$name"_R1_trimmed.fastq" -2 ../trimmed_data/$name"_R2_trimmed.fastq" \
            -o $name --align none --graphical F --cpu $SLURM_CPUS_PER_TASK --plus
metaxa2_ttt -i $name".taxonomy.txt" -o $name
```

When all Metaxa2 array jobs are done, we can combine the results to an OTU table. Different levels correspond to different taxonomic levels.  
When using any 16S rRNA based software, be cautious with species (and beyond) level classifications. Especially when using short reads.  
We will look at genus level classification.
```
# Genus level taxonomy
cd Metaxa2
metaxa2_dc -o metaxa_genus.txt *level_6.txt
```
