#!/bin/bash
## code adapted from
## http://jensd.be/248/linux/use-inotify-tools-on-centos-7-or-rhel-7-to-watch-files-and-directories-for-events

# Parse the command-line arguments
while [ "$#" -gt "0" ]; do
  case "$1" in
    -ac|--account-name)
      ACCOUNTNAME="$2"
      shift 2
    ;;
    -wd|--watch-dir)
      watchdir="$2"
      shift 2
    ;;
    -bn|--blob-name)
      BLOBNAME="$2"
      shift 2
    ;;
    -lg|--log-file)
        logfile="$2"
        shift 2
    ;;
    -cf|--complete-file)
        completefile="$2"
        shift 2
    ;;
    -ad|--archive-dir)
        archivedir="$2"
        shift 2
    ;;
    -md|--moveto-dir)
        movetodir="$2"
        shift 2
    ;;
    -us|--upload-script)
        UPLOADTOBLOBSCRIPTPATH="$2"
        shift 2
    ;;    
    -c|--container)
        CONTAINER="$2"
        shift 2
    ;;    
    -ta|--time-add)
        TIMEADD="$2"
        shift 2
    ;;    
    -*|--*)
      # Unknown option found
      echo "Unknown option $1."

      exit 1
    ;;  
    *)
      CMD="$1"
      break
    ;;
  esac
done

inotifywait -m -e CLOSE,CREATE $watchdir | while read path action file; do
        ts=$(date +"%C%y%m%d%H%M%S")
        echo "$ts :: file: $file :: $action :: $path">>$logfile
	## Allow files to land in incoming folder until a "completion" file is created.
	## Creation file to trigger file transfers to BLOB and to the archive folder
	if [[ $action == "CREATE" && $file == $completefile ]]; then
		echo "File transfer completed"
		
		## remove completion file
		rm $watchdir/$file
		tsArch=$(date +"%C%y%m%d%H%M%S")
        	echo "$tsArch :: file: $file :: Remove completion file :: $path/$file">>$logfile

		## create timestamped directories
		#mkdir $movetodir/$ts
		mkdir $archivedir/$tsArch

		#echo "Archive directory created"
		ts=$(date +"%C%y%m%d%H%M%S")
        	echo "$ts :: Archive directory created: $archivedir/$ts">>$logfile

		## copy files from landing zone to BLOB - replace code with azure CLI code
		#cp $watchdir/* $movetodir/$ts
		echo "Begin file upload"
		for f in `ls $watchdir`; do
			
			ts=$(date +"%C%y%m%d%H%M%S")
        	echo "$ts :: file: $f :: Begining upload to blob storage container: $CONTAINER">>$logfile
			echo "TIMEADD = $TIMEADD"
			case $TIMEADD in
				"1 hour")
					TSROUND=$(date -d '+1 hour' +"%C%y%m%d%H")
					(( TSROUND *= 100 ))
					#echo "1 hour - TSROUND = $TSROUND"
					# TSYEAR=${TSROUND:0:4}
					# TSMONTH=${TSROUND:4:2}
					# TSDAY=${TSROUND:6:2}
					# TSTIME=${TSROUND:(-4)}
					# TSPATH="$TSYEAR/$TSMONTH/$TSDAY/$TSTIME/"
					#echo "1 hour - TSROUND = $TSROUND - PATH = $TSPATH"
				;;
				"15 minute")
					TSROUND=$(date +"%C%y%m%d%H%M")
					(( TSROUND /= 15, TSROUND *= 15, TSROUND += 15 ))

					#echo "15 minute - TSROUND = $TSROUND - PATH = $TSPATH"
				;;
				*)
					TSROUND=$(date +"%C%y%m%d%H%M")
					# TSPATH=""
					echo "none - TSROUND = $TSROUND"
				;;
			esac
			TSYEAR=${TSROUND:0:4}
			TSMONTH=${TSROUND:4:2}
			TSDAY=${TSROUND:6:2}
			TSTIME=${TSROUND:(-4)}
			TSPATH="$TSYEAR/$TSMONTH/$TSDAY/$TSTIME/"
			#echo "TSROUND = $TSROUND"
			$UPLOADTOBLOBSCRIPTPATH/automate_push_to_blob.sh --account-name $ACCOUNTNAME --container-name $CONTAINER --upload-file $watchdir/$f --blob-name "$TSPATH$TSROUND-$f" --log-file $logfile
		done

		## generate list of files being moved into archive folder
		#mvFiles="Moving `ls $watchdir`"
		echo "Move files to archive directory"
		## Move files
		ts=$(date +"%C%y%m%d%H%M%S")
		for f in `ls $watchdir`; do
			mv $watchdir/$f $archivedir/$tsArch/$f
			echo "$ts :: file: $f :: Moving file to: $archivedir/$tsArch">>$logfile
		done
		ts=$(date +"%C%y%m%d%H%M%S")
		echo "$ts :: Completed file move to: $archivedir/$tsArch"
	fi

done

exit 0
