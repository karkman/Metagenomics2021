*Antti Karkman, Igor S Pessi and Jenni Hultman*

# Metagenome analysis tundra soil metagenomes
Log into Puhti, either with ssh (Mac/Linux) or PuTTy (Windows)

__All the scripts are to be run in `your_name` folder!__

## Data download
First set up the your directory where you wil perform all the tasks for this course and create some folders. All the task are performed at Puhti scratch-folder in the course directory `project_2001499`.

```
mkdir $USER
cd $USER
mkdir TRIMMED

```

Check with `ls` what kind of folders were created. What kind of folder did `mkdir $USER ` create?

The raw data used on this course can be found from `/scratch/project_2001499/RAWDATA`. Do not copy data but use link to this folder in all of the needed tasks. Why we do not want 14 students to download data to their own folders?

## QC and trimming
QC for the raw data (takes few min, depending on the allocation). Go to your own folder under project_2001499 and make a folder called e.g. `FASTQC` for the QC reports.  

QC does not require lot of memory and can be run on the interactive nodes using `sinteractive`.   

Activate the biokit environment and open interactive node
```
module load biokit
sinteractive
```

## Run fastqc

Run fastqc to the files stored in the RAWDATA folder. What does the -o flag refer to?
```
fastqc /scratch/project_2001499/RAWDATA/*fastq.gz -o FASTQC/
```

## Then combine the reports in FASTQC folder with multiqc 
```
multiqc FASTQC/* -o FASTQC --interactive

```

Copy the resulting HTML file to your local machine with `scp` from the command line (Mac/Linux) or *WinSCP* on Windows. Have a look at the QC report with your favourite browser.  

After inspecting the output, it should be clear that we need to do some trimming.  

__What kind of trimming do you think should be done?__

For trimming we have a array script that runs `cutadapt` for each file in the `RAWDATA`folder located at `/scratch/project_2001499`.    
Go to your folder folder and copy the array script from `/scratch/project_2001499/SBATCH_SCRIPTS`. Check the script for example with command `less`. The adapter sequences that you want to trim after `-a` and `-A`. What is the difference with `-a` and `-A`? And what is specified with option `-p` or `-o`? And how about `-m`and `-j`? You can find the answers from Cutadapt [manual](http://cutadapt.readthedocs.io).

Then we need to submit our jos to the SLURM system. Make sure to submit it from your own folder. More about CSC batch jobs here: https://docs.csc.fi/computing/running/creating-job-scripts-puhti/.  

`sbatch scripts/cut_batch.sh`  

You can check the status of your job with:  

`squeue -l -u $USER`  

After the job has finished, you can see how much resources it actually used and how many billing units were consumed. `JOBID` is the number after the batch job error and output files.  

`seff JOBID`  

After lunch break let's check the results from the trimming.

Go to the folder containing the trimmed reads (`TRIMMED`) and view the Cutadapt log. Can you answer:

* How many read pairs we had originally?
* How many reads contained adapters?
* How many read pairs were removed because they were too short?
* How many base calls were quality-trimmed?
* Overall, what is the percentage of base pairs that were kept?

Then make a new folder (`FASTQC`) for the QC files of the trimmed data. 

Run FASTQC and MultiQC again as you did before trimming.  

## run QC on the trimmed reads
```
fastqc ./*.fastq -o FASTQC/ -t 4
multiqc ./ --interactive

```
Copy it to your local machine as earlier and look how well the trimming went.  


## Read based analysis
We will annotate short reads with tool called Megan (https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/algorithms-in-bioinformatics/software/megan6/) and Metaxa (https://microbiology.se/software/metaxa2/).  These will take a while to run and therefore will run it already today to have the results ready on Tuesday. 

Altogether we will use four different programs for read based analysis: `seqtk`, `DIAMOND`, `MEGAN` and `METAXA`.

MEGAN utilizes program called Diamond which claims to be up to 20,000 times faster than Blast to annotate  reads against the database of interest. Here we will use NCBI nr database which has been formatted for DIAMOND.

Then we will use MEGAN to parse the annotations and get taxonomic and functional assignments.

In addition to DIAMOND and MEGAN, we will also use another approach to get taxonomic profiles using METAXA. Metaxa runs in two steps: the first command finds rRNA genes among our reads using HMM models and then annotates them using BLAST and a reference database.

Since the four samples have been sequenced really deep, we will utilize only subset of them for read based analysis. The subsampled 2 000 000 sequences represent the total community for this analysis. Tool `Seqtk` is used for this. 

First, make following folders to your own folder: MEGAN, RESAMPLED and METAXA. 

You can find READ_BASED.sh script from the same location as before. Then copy it to your folder. How can you check in which folder you are?

```
/scratch/project_2001499/SBATCH_SCRIPTS/READ_BASED.sh

```
Launch READ_BASED.sh as you did for Cutadapt earlier today. 

The database NCBI nr is being updated by CSC  so we do not need to copy it from NCBI ourselves. The databases found at CSC can be listed with command xxx in Puhti. 

