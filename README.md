# Dumpfile password extractor
This bash script can be used to extract passwords from most common dump/leak files.

## Note

Test branches are experimental, might be unfinished or might cause infinite regression of reality and the end of the universe.
Please check the code before you use the Test branch.

## Usage:

```
extractpaswd.sh source_file
extractpaswd.sh source_file <target_directory>
extractpaswd.sh source_file <target_directory> -debug
```

If `<target_directory>` is not provided the directory of `source_file` will be used.

Files formats that this script is parsing:
```
email:password
email|password
email;password
password:email
something-resembling-email:password
```

## Standard version vs Parallel version
Parallel version of this script relies on 'parallel' package (https://www.gnu.org/software/parallel/).
Before you can use the parallel version you have to install `parallel`. It is available precompiled for a lot of platforms (just ask your local package vendor like yum, apt, or homebrew).

Differences:

Standard | Parallel
------|------
it's awesome | it's awesome x (number of threads)
it's quite fast | it's quite fast x (number of threads)

I think you get the gist.

In a real life, on a MacBook Pro with 2,5 GHz Intel Core i7 (4 cores), while parsing ~2Gb file, the standard version managed to parse it in 8m32s. Parallel version on the same machine, with the same file took only 3m15s.

Inside the parallel version there are a few options that can be tweaked according to your needs (I might add some switches to play around with them interactively later on). Right now the settings are a result of a few hours of tweaking and getting results that will give fast results and responsive feedback (for progress).
The interesting switches are:

`--block 100M` - this setting is a balanced for larger files (>1GB). Going higher (200M, 300M +) can shave a few seconds from the result, but at the same time the progress bar will be less responsive and will give feedback on progress less often. Decreasing this to 50M will make the progress bar show progress more often but again you will have to spend a few more seconds staring at it.

`--block -1` - because the parts that have this settings are dealing with rather small files, they usually can be just chopped into amount of jobs equal to your number of available threads and run in one go. This setting literally means "chop input into only that many parts to provide each job -X tasks". So for 4 threads this means chop in 4, for 8 threads chop in 8 parts etc. You can change it to -2 or any other number but there is no real benefit if the files are small and actually you will probably lose some performance.


## How it works:
TBD

WARNING: The script is designed to work in non-destructive way. But you are using it at your own peril. I cannot be liable for Earth standing still, your cat getting possessed or your computer bursting in flames.

copyleft. (CC BY-SA 4.0) Do whatever you want with it.
