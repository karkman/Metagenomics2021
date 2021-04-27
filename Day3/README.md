# Day 3

| Time      | Activity                             | Slides                                         | Hands-on                                              |
|-----------|--------------------------------------|------------------------------------------------|-------------------------------------------------------|
| Morning   | Assembly                             | [Link here](assembly.pdf)                      | [Link here](#Assembly)                                |
| Morning   | Genome resolved metagenomics         | [Link here](genome-resolved-metagenomics.pdf)  |                                                       |
| Afternoon | Genome resolved metagenomics  cont'd |                                                | [Link here](#genome-resolved-metagenomics-with-anvio) |


## Assembly
We will assemble all 4 samples indivially and use [Megahit assembler](https://github.com/voutcn/megahit) for the job. In addition, we will use MetaQuast to get some statistics about our assembly.

Megahit is an ultra fast assembly tool for metagenomics data. It is installed to CSC and be loaded with following command:

```
module load biokit
```

Assembling metagenomic data can be very resource demanding and we need to do it as a batch job.

Copy the  script called MEGAHIT.sh from the SBATCH folder to your own directory and submit the batch job as previously.

What do the following flags mean?
```
--min-contig-len 1000
--k-min 27
--k-max 127
--k-step 10
--memory 0.8
--num-cpu-threads 8
```

However, as this is only one week course we cannot wait for your assemblies to finish but let's terminate the running jobs.

What was the command to view on-going batch jobs? You can terminate the sbatch job byt typing

```
scancel JOBID
```
Terminate your job and check that is it no longer in your list of jobs.

We have run the assemblies for you and now copy the assembled metagenomes from `/scratch/project_2001499/hultman/ASSEMBLY_MEGAHIT`. What kind of files did you copy? Please take a look at the log-files.

Questions about the assembly
* Which version of megahit did we actually use for the assemblies?
* How long did the assemblies take to finish?
* Which sample gave the longest contig?


## Assembly quality statistics
Let's take a look at the assemblies in a bit more detail with tool [MetaQUAST](http://bioinf.spbau.ru/metaquast).

Since the assmebly woud have taken too long to finish, we ran the assembly for you.
The assembly files can be pretty big as well, so you will make a softlink to the assembly folder to save some space.

```bash
cd /scratch/project_2001499/$USER
ln -s ../COURSE_FILES/ASSEMBLY_MEGAHIT/
```

Then we'll run assembly QC using `MetaQUAST`.
First have a look at the different options that you specify.

```bash
module load biokit
metaquast.py -h
```

Open an interactive session for QC and allocate __1 hour__, __10 Gb of memory__ and __4 CPUs/threads__.  
Then when you're connecteed to the login node, run `MetaQUAST`.

```bash
sinteractive -i
metaquast.py ASSEMBLY_MEGAHIT/*/final.contigs.fa \
               -o METAQUAST_FAST \
               --threads 4 \
               --fast \
               --max-ref-number 0 &> metaquast.fast.log.txt
```

Copy folder called "METAQUAST_FAST" to your computer. You can view the results (`report.html`) in your favorite browser.

Questions about the assembly QC

* Which assembly has the longest contig when also long reads assemblies are included?
* Which assembly had the most contigs?
* Were the long read assemblies different from the corresponding short read assemblies?
* If yes, in what way?


# Genome-resolved metagenomics with Anvi'o

Anvio is an analysis and visualization platform for omics data. You can read more from Anvio's [webpage](http://merenlab.org/software/anvio/).

![alt text](/Figure/Screen%20Shot%202017-12-07%20at%2013.50.20.png "Tom's fault")

First open interactive node with 4 cores and go to your course folder and make a new folder called ANVIO. All task on this section are to be done in this folder.

```
sinteractive -A project_2001499 -c 4 -m 10000

mkdir ANVIO
cd ANVIO
```
We need to do some tricks for the contigs from assembly before we can use them in anvi'o. We will do this for one sample and you will get the needed data for rest of samples from ANVI-TUTORIAL. For anvi'o you'll need to load bioconda and activate anvio-7 virtual environment.  
Open a screen for anvi'o workflow. `screen -S anvio`

```
export PROJAPPL=/projappl/project_2001499
module load bioconda/3
source activate anvio-7
```
## Rename the scaffolds and select those >5000nt.
Anvio wants sequence IDs in your FASTA file as simple as possible. Therefore we need to reformat the headerlines to remove spaces and non-numeric characters. Also contigs shorter than 5000 bp will be removed.


```
anvi-script-reformat-fasta ../ASSEMBLY_MEGAHIT/Sample03/final.contigs.fa -l 5000 --simplify-names \
                            --prefix MEGAHIT_sample03 -r REPORT -o MEGAHIT_sample03_5000nt.fa
````
Deattach from the screen with `Ctrl a+d`  


## Generate CONTIGS.db

Contigs database (contigs.db) contains information on contig length, open reading frames (searched with Prodigal) and kmers. See [Anvio webpage](http://merenlab.org/2016/06/22/anvio-tutorial-v2/#creating-an-anvio-contigs-database) for more information.  

```
anvi-gen-contigs-database --contigs-fasta MEGAHIT_sample03_5000nt.fa --output-db-path MEGAHIT_sample03_5000nt_CONTIGS.db \
                          -n MEGAHIT_sample03_5000nt --num-threads 4
```
## Run HMMs to identify single copy core genes for Bacteria, Archaea and Eukarya, plus rRNAs
```
anvi-run-hmms --contigs-db MEGAHIT_sample03_5000nt_CONTIGS.db --num-threads 4
```
## Mapping the reads back to the assembly
Next thing to do is mapping all the reads back to the assembly. We use the renamed >5000 nt contigs and do it sample-wise, so each sample is mapped separately using the trimmed R1 & R2 reads.  

However, since this would take three days, we have run this for you and the data can be found from `COURSE_DATA/MEGAHIT_BINNING/`
Let's make a softlink to that folder as well. Make sure you make the softlink to your `ANVIO` folder

```bash
ln -s ../../COURSE_FILES/BINNING_MEGAHIT/
```

Next we will profile the samples using the DB and the mapping output. Write an array script for the profiling and submit it to the queue.

```
#!/bin/bash -l
#SBATCH -J array_profiling
#SBATCH -o array_profiling_out_%A_%a.txt
#SBATCH -e array_profiling_err_%A_%a.txt
#SBATCH -t 01:00:00
#SBATCH --mem-per-cpu=1000
#SBATCH --array=1-4
#SBATCH -n 1
#SBATCH --cpus-per-task=6
#SBATCH -p serial

SAMPLE=Sample0${SLURM_ARRAY_TASK_ID}

export PROJAPPL=/projappl/project_2001499
module load bioconda/3
source activate anvio-7

anvi-profile --input-file BINNING_MEGAHIT/Sample03/MAPPING/$SAMPLE.bam \
               --output-dir PROFILES/$SAMPLE \
               --contigs-db MEGAHIT_sample03_5000nt_CONTIGS.db \
               --num-threads 20 &> $SAMPLE.profilesdb.log.txt
```
Submit the job with `sbatch` as previously.  


## Merging the profiles

Now you have done this for one sample. However, as we have four samples, we will use the data from all samples. We have pre-run this for you and data can be found from COURSE_DATA
When the profiling is done, you can merge them with thus command.

```
anvi-merge PROFILES/*/PROFILE.db \
           --output-dir MERGED_PROFILES \
           --contigs-db MEGAHIT_sample03_5000nt_CONTIGS.db \
           --enforce-hierarchical-clustering &> Sample03.merge.log.txt
```

### Tunneling the interactive interafce

Although you can install anvi'o on your own computer (and you're free to do so, but we won't have time to help in that), we will run anvi'o in Puhti and tunnel the interactive interface to your local computer.  
To be able to to do this, everyone needs to use a different port for tunneling and your port will be __8080 + your number given on the course__. So `Student 1` will use port 8081. If the port doesn't work, try __8100 + your number__.  

Connecting using a tunnel is a bit tricky and involves several steps, so pay special attention.  
First we need to open an interactive session inside a screen and then log in again with a tunnel using the computing node identifier.

Mini manual for `screen`:
* `screen -S NAME` - open a screen and give it a session name `NAME`
* `screen` - open new screen without specifying any name
* `screen -ls` - list all open sessions
* `ctrl + a` + `d` - to detach from a session (from inside the screen)
* `screen -r NAME` - re-attach to a detached session using the name
* `screen -rD` - re-attach to a attached session
* `exit` - close the screen and kill all processes running inside the screen (from inside the screen)

So open a normal connection to Puhti and go to your course folder. Take note which login node you were connected.   
Then open an interactive session and specify that you need 8 hours and 10 Gb of memory.  
Other options can stay as they are.  
Note the computing node identifier before logging out.

```bash
cd /scratch/project_2001499/$USER
# Take note whether you were connected to login1 or login2. Screens are login node specific.
screen -S anvio
sinteractive -i
# And after this change the time and memory allocations.
# When your connected to the computing node, check the identifier and detach from the screen
```

Then you can log out and log in again, but this time in a bit different way.  
You need to specify your __PORT__ and the __computing node__ to which you connected and also the __login node__ you were connected the first time.  

```bash
ssh -L PORT:NODEID.bullx:PORT USERNAME@puhti-loginX.csc.fi
```

And in windows using Putty:  
In SSH tab select "tunnels". Add:  
- Source port: PORT  
- Destination: localhost:PORT  

Click add and connect as usual.

Then go back to your screen and launch the interactive interface.  
Remember to change the port.

```
anvi-interactive -c  MEGAHIT_sample03_5000nt_CONTIGS.db -p MERGED_PROFILES/PROFILE.db -P PORT
```

Then open google chrome and go to address that anvi'o address

http://localhost:PORT

**Again change XXXX to your port number**
