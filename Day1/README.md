*Antti Karkman, Igor S Pessi and Jenni Hultman*

# Connecting to Puhti

## Windows users

* Launch PuTTY
* In “Host Name (or IP address)”, type **puhti.csc.fi** and click “Open”
* In the following dialogue window, choose “Yes”
* Type your CSC username and hit "Enter"
* Type your password and hit "Enter"
* To logout just type `exit` and hit "Enter"

## MacOS users

* Launch Terminal (e.g. open the Launchpad and type **terminal**)
* Type `ssh **user**@puhti.csc.fi` and hit "Enter" (change "user" for your own CSC username)
* In the following dialogue, type `yes` and hit "Enter"
* Type your password and hit "Enter"
* To logout first type `exit`, hit "Enter", and close the Terminal window

# Introduction to Unix: exercises
Most of our activities will be done using the Unix command line (aka Unix shell).  
It is thus highly recommend to have at least a basic grasp of how to get around in the Unix shell.  
We will now dedicate half hour or so to follow some basic to learn (or refresh) the basics of the Unix shell.  

## Important notes

Things inside a box like this...

```bash
mkdir unix_shell
cd unix_shell
```
...represent commands you need to type in the shell. Each line is a command. Commands have to be typed in a single line, one at a time. After each command, hit “Enter” to execute it.

Things starting with a pound sign (or hashtag)...

```bash
# This is a comment and is ignored by the shell
```

...represent comments embedded in the code to give instructions to the user. Anything in a line starting with a `#` is ignored by the shell. You can type it if you want, but nothing will happen (provided you start with a `#`).

We will be using different commands with different syntaxes. Different commands expect different types of arguments. Some times the order matters, some times it doesn't. If you are unsure, the best way to check how to run a command is by taking a look at its manual with the command `man`. For example, if you want to look at the manual for the command `mkdir` you can do:

```bash
man mkdir

# You can scroll down by hitting the space bar
# To quit, hit "q"
```

## Creating and navigating directories

First let's see where we are:

```bash
pwd
```

Are there any files here? Let's list the contents of the folder:

```bash
ls
```

Let's now create a new folder called `unix_shell`. In addition to the command (`mkdir`), we are now passing a term (also known as an argument) which, in this case, is the name of the folder we want to create:

```bash
mkdir unix_shell
```

Has anything changed? How to list the contents of the folder again?

<details>
<summary>
HINT (CLICK TO EXPAND)
</summary>

> ls

</details>  

---

And now let's enter the `unix_shell` folder:

```bash
cd unix_shell
```

Did it work? Where are we now?

<details>
<summary>
HINT
</summary>

> pwd

</details>  

## Creating a new file

Let's create a new file called `myfile.txt` by launching the text editor `nano`:

```bash
nano myfile.txt
```

Now inside the nano screen:

1. Write some text

2. Exit with ctrl+x

3. To save the file, type **y** and hit "Enter"

4. Confirm the name of the file and hit "Enter"

List the contents of the folder. Can you see the file we have just created?


## Copying, renaming, moving and deleting files

First let's create a new folder called `myfolder`. Do you remember how to do this?

<details>
<summary>
HINT
</summary>

> mkdir myfolder

</details>  

---

And now let's make a copy of `myfile.txt`. Here, the command `cp` expects two arguments, and the order of these arguments matter. The first is the name of the file we want to copy, and the second is the name of the new file:

```bash
cp myfile.txt newfile.txt
```

List the contents of the folder. Do you see the new file there?  

Now let's say we want to copy a file and put it inside a folder. In this case, we give the name of the folder as the second argument to `cp`:

```bash
cp myfile.txt myfolder
```

List the contents of `myfolder`. Is `myfile.txt` there?

```bash
ls myfolder
```

We can also copy the file to another folder and give it a different name, like this:

```bash
cp myfile.txt myfolder/copy_of_myfile.txt
```

List the contents of `myfolder` again.  Do you see two files there?

Instead of copying, we can move files around with the command `mv`:

```bash
mv newfile.txt myfolder
```

Let's list the contents of the folders. Where did `newfile.txt` go?

We can also use the command `mv` to rename files:

```bash
mv myfile.txt myfile_renamed.txt
```

List the contents of the folder again. What happened to `myfile.txt`?

Now, let's say we want to move things from inside `myfolder` to the current directory. Can you see what the dot (`.`) is doing in the command below? Let's try:

```bash
mv myfolder/newfile.txt .
```

Let's list the contents of the folders. The file `newfile.txt` was inside `myfolder` before, where is it now?  

The same operation can be done in a different fashion. In the commands below, can you see what the two dots (`.`) are doing? Let's try:

```bash
# First we go inside the folder
cd myfolder

# Then we move the file one level up
mv myfile.txt ..

# And then we go back one level
cd ..
```

Let's list the contents of the folders. The file `myfile.txt` was inside `myfolder` before, where is it now?  

We have so many identical files in our folders. Let's clean things up and delete some files :

```bash
rm newfile.txt
```

Let's list the contents of the folder. What happened to `newfile.txt`?  

When deleting files, pay attention in what you are doing: **if you accidently remove the wrong file, it is gone forever!**

And now let's delete `myfolder`:

```bash
rm myfolder
```

It didn't work did it? An error message came up, what does it mean?

```bash
rm: cannot remove ‘myfolder’: Is a directory
```

To delete a folder we have to modify the command further by adding the recursive flag (`-r`). Flags are used to pass additional options to the commands:

```bash
rm -r myfolder
```

PS: the following command also works, but only if the folder is empty:

```bash
rmdir myfolder
```

Let's list the contents of the folder. What happened to `myfolder`?  

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
