#Dumpfile password extractor
This bash script can be used to extract passwords form most common dump files.

##Usage:

```
extractpaswd source_file
extractpaswd source_file <target_directory>
extractpaswd source_file <target_directory> -debug
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

How it works:
TBD

WARNING: The script is desing to work in non-destructive way. But you are using it at your own peril. I cannot be liable for Earth standing still, your cat getting possessed or your computer bursting in flames.

copyeft. (CC BY-SA 4.0) Do whatever you want with it.
