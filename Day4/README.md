# Day 4

| Time      | Activity                     | Slides                                        | Hands-on                                   |
|-----------|------------------------------|-----------------------------------------------|--------------------------------------------|
| Morning   | Genome-resolved metagenomics | [Link here](/Day3/genome-resolved-metagenomics.pdf) | [Link here](#genome-resolved-metagenomics) |
| Afternoon | Genome-resolved metagenomics |                                               | [Link here](#genome-resolved-metagenomics) |

## Genome-resolved metagenomics

Next step in our analysis is genome-resolved metagenomics using anvi'o. We ran all the steps to produce the files for anvi'o yesterday.
But let's start with a smaller tutorial dataset. It's a subset taken from Sample03.

### Tunneling the interactive interafce (recap from yesterday)

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
sinteractive -A project_2001499 -c 4 -m 10G -t 08:00:00
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
- Destination: NODEID.bullx:PORT

Click add and connect as usual, making sure you will be connected to the right login node.

Then we can start to work with our tutorial data in anvi'o.  
Activate anvi'o v.7 virtual environment and copy the folder containing the tutorial files to you own course folder.  
Go to the folder and see what it contains.

```bash
screen -r anvio
module purge
export PROJAPPL=/projappl/project_2001499
module load bioconda/3
source activate  anvio-7
cp -r ../COURSE_FILES/ANVI-TUTORIAL .
cd ANVI-TUTORIAL
ls -l
```
You should have there the `CONTIGS.db` and `PROFILE.db` plus an auxiliary data file called `AUXILIARY-DATA.db`.

First have a look at some basic statistics about the contigs database.  
*__NOTE!__ You need to specify your port.*

```bash
anvi-display-contigs-stats CONTIGS.db -P PORT
```
Now anvi'o tells you to the server address. It should contain your port number. Copy-paste the address to your favourite browser. Chrome is preferred.

One thing before starting the binning, let's check what genomes we might expect to find from our data based on the single-copy core genes (SCGs).

```bash
anvi-estimate-scg-taxonomy -c CONTIGS.db \
                           -p PROFILE.db \
                           --metagenome-mode \
                           --compute-scg-coverages

```

Then you can open the interactive interface and explore our data and the interface.  
*__NOTE!__ You need to specify your port in here as well.*

```bash
anvi-interactive -c CONTIGS.db -p PROFILE.db -P PORT
```

You might notice that it's a bit slow to use sometimes. Even this tutorial data is quite big and anvi'o gets slow to use when viewing the whole data. So next step is to split the data in to ~ 5-8 clusters (__bins__) that we will work on individually.

Make the clusters and store them in a collection called `PreCluster`. Make sure that the bins are named `Bin_1`, `Bin_2`,..., `Bin_N`. (or anything else that's easy to remember).  
Then you can close the server from the command line.

Next we'll move on to manually refine each cluster we made in the previous step. We'll do this to each bin in our collection called `PreCluster`.  

To check your collections and bins you can run `anvi-show-collections-and-bins -p PROFILE.db`

If you know what you have, go ahead and refine all the bins on your collection.
After refining, remember to store the new bins and then close the server from command line and move on to the next one.

```bash
anvi-refine -c CONTIGS.db -p PROFILE.db -C COLLECITON_NAME -b BIN_NAME -P PORT
```

After that's done, we'll rename the bins to a new collection called `PreliminaryBins` and add a prefix to each bin.

```bash
anvi-rename-bins -c CONTIGS.db -p PROFILE.db --collection-to-read Precluster --collection-to-write PreliminaryBins --prefix Preliminary --report-file REPORT_PreliminaryBins
```
Then we can also make a summary of the bins we have in our new collection `PreliminaryBins`.

```bash
anvi-summarize -c CONTIGS.db -p PROFILE.db -C PreliminaryBins -o SUMMARY_PreliminaryBins
```
After that's done, copy the summary folder to your local machine ands open `index.html`.

From there you can find the summary of each of your bins. In the next step we'll further refine each bin that meets our criteria for a good bin but still has too much redundancy. In this case completeness > 80 % and redundancy > 10 %. So refine all bins that are more than 80 % complete and have more than 10 % redundancy.

When you're ready it's time to again rename the bins and run the summary on them.  
Name the new collection `Bins` and use prefix `Sample03`.

Now we should have a collection of pretty good bins out of our data. The last step is to curate each bin to make sure it represent only one population. And finally after that we can call MAGs from our collection. We will call MAGs all bins that are more than 80 % complete and have less than 5 % redundancy.  

```bash
anvi-rename-bins -c CONTIGS.db -p PROFILE.db --collection-to-read Bins --collection-to-write MAGs --prefix Sample03 --report-file REPORT_MAGs \
                  --call-MAGs --min-completion-for-MAG 80 --max-redundancy-for-MAG 5
```

And finally you can make a summary of your MAGs before moving on.

```bash
anvi-summarize -c CONTIGS.db -p PROFILE.db -C MAGs -o SUMMARY_MAGs
```

Then it's finally time to start working with the full data set from Sample03.
