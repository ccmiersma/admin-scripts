#!/bin/bash

DATE=`date +%Y%m%d`
TIME=`date +%H%M`
DATETIME=$DATE$TIME
PG_HOME=/var/lib/pgsql
BACKUP_BASEDIR=$PG_HOME/backups
WORKING_DIR=$BACKUP_BASEDIR/$DATETIME
BACKUP_DIR=$WORKING_DIR/data
ARCHIVE_LOG_DIR=xlog
BACKUP_LOG=$PG_HOME/backup.log
CLEANUP_LOG=$PG_HOME/cleanup.log
BACKUP_ARCHIVE=$BACKUP_BASEDIR/$DATETIME.tar.gz

cd $PG_HOME || ( echo "Error: unable to cd to $PG_HOME" && exit 2)

mkdir $WORKING_DIR && echo "Created $WORKING_DIR successfully. Starting backup at $DATETIME..." > $BACKUP_LOG || ( echo "Unable to create working directory $WORKING_DIR or backup log $BACKUP_LOG" && exit 2)


pg_basebackup -R -x -D $BACKUP_DIR -l $DATETIME &>> $BACKUP_LOG || ( echo "Error during pg_basebackup." && exit 2)

echo "Finished pg_basebackup to $BACKUP_DIR" &>> $BACKUP_LOG || ( echo "Unable to log" && exit 1)

rsync -axvAHX $PG_HOME/$ARCHIVE_LOG_DIR $WORKING_DIR/$ARCHIVE_LOG_DIR &>> $BACKUP_LOG || ( echo "Error during archive log sync." && exit 2)

echo "Finished syncing archive logs." &>> $BACKUP_LOG || ( echo "Unable to log" && exit 1)

echo "Cleaning up old archive logs..." &>> $BACKUP_LOG || ( echo "Unable to log" && exit 1)

touch -d "$DATE $TIME" $BACKUP_LOG

cd $ARCHIVE_LOG_DIR || ( echo "Unable to cd into $ARCHIVE_LOG_DIR" && exit 2)
find ./ ! -newer $BACKUP_LOG -exec rm -f {} + > $CLEANUP_LOG || ( echo "Error deleting old files" && exit 2)
cd - &> /dev/null || ( echo "Unable to cd out of $ARCHIVE_LOG_DIR" && exit 2)

cat $PG_HOME/cleanup.log &>> $BACKUP_LOG

rm -f $CLEANUP_LOG

echo "Archiving backup..." &>> $BACKUP_LOG || ( echo "Unable to log" && exit 1)

cd $WORKING_DIR || ( echo "Unable to cd into $WORKING_DIR" && exit 2)
tar cfz $BACKUP_ARCHIVE ./ &>> $BACKUP_LOG || ( echo "Error while archivng backup." && exit 2)
cd - &> /dev/null || ( echo "Unable to cd out of $WORKING_DIR" && exit 2)

echo "Removing working directory: $WORKING_DIR" &>> $BACKUP_LOG || ( echo "Unable to log" && exit 1)

rm -rf $WORKING_DIR &>> $BACKUP_LOG || ( echo "Error while removing $WORKING_DIR" && exit 2)

echo "Removed working directory." &>> $BACKUP_LOG || ( echo "Unable to log" && exit 1) 

find $BACKUP_BASEDIR -mtime +7 -delete &>> $BACKUP_LOG || ( echo "Error deleting old backups." && exit 2)

echo "Backup succeeded." &>> $BACKUP_LOG || ( echo "Unable to log" && exit 1)








