# KVMBackup
#This is just a script to do KVMBackups to /backup unless you change it. 

#There is no need to select the KVMs as it will backup all the running KVMs. 

#None off the shutoff KVMs are backed up as you could just dumpxml on those and make a copy of /var/lib/livirt/images as needed. 

After a dirve is mounted in the backup destination you will need to put a file donotdelete.txt 

touch /backup/donotdelete.txt

