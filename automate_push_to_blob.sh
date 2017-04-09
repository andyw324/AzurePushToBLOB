#!/bin/bash
# Pushes files from directory to BLOB


# Parse the command-line arguments
while [ "$#" -gt "0" ]; do
  case "$1" in
    -ac|--account-name)
      ACCOUNTNAME="$2"
      shift 2
    ;;
    -uf|--upload-file)
      FILETOUPLOAD="$2"
      shift 2
    ;;
    -bn|--blob-name)
      BLOBNAME="$2"
      shift 2
    ;;
    -lg|--log-file)
        LOGFILE="$2"
        shift 2
    ;;
    -c|--container-name)
        CONTAINER="$2"
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

## Check user / service principal logged in
USER=`az account show --query user.name`
if [[ $USER == "" ]]; then
    echo "User not logged into Azure - please ensure a valid user / service principal is currently logged in before continuing"
    if [[ $LOGFILE == "" ]]; then    
        ts=$(date +"%C%y%m%d%H%M%S") 
        echo "$ts :: ERROR - no valid user / service principal account logged into Azure - aborting file upload">>$LOGFILE
    fi
    exit 1
fi

if [[ $BLOBNAME == "" ]]; then BLOBNAME=$FILETOUPLOAD; fi

## Generate expiry date
EXPIRYDATE=`TZ=UTC date +"%Y-%m-%dT%H:%MZ" -d "+5 minutes"`

## Generate account SAS
BLOB_SAS_TOKEN=`az storage account generate-sas --resource-types o --services b --https-only --account-name $ACCOUNTNAME --permissions cw --expiry $EXPIRYDATE`

## Check whether SAS Token successfully generated and if so upload file
if [[ $BLOB_SAS_TOKEN == "" ]]; then    
    if [[ $LOGFILE != "" ]]; then 
        ts=$(date +"%C%y%m%d%H%M%S") 
        echo "$ts :: ERROR - No Azure Storage SAS Token generated - aborting file upload">>$LOGFILE
    fi
    exit 1
else
    if [[ $LOGFILE != "" ]]; then
        ts=$(date +"%C%y%m%d%H%M%S")
        echo "$ts :: SAS token successfully generated - expires on $EXPIRYDATE">>$LOGFILE
        ts=$(date +"%C%y%m%d%H%M%S")
        echo "$ts :: Uploading file: $FILETOUPLOAD">>$LOGFILE
        az storage blob upload -c $CONTAINER -f $FILETOUPLOAD -n $BLOBNAME --account-name $ACCOUNTNAME --sas-token ${BLOB_SAS_TOKEN:1:-1} |& tee -a $LOGFILE
        if [[ `tail -1 $LOGFILE` =~ "Percent complete: %100.0" ]]; then
            UPLOADSTATUS="completed"
        else
            UPLOADSTATUS="failed"
        fi
        ts=$(date +"%C%y%m%d%H%M%S")    
        echo "$ts :: File upload $UPLOADSTATUS: $FILETOUPLOAD">>$LOGFILE
    else
        az storage blob upload -c $CONTAINER -f $FILETOUPLOAD -n $BLOBNAME --account-name $ACCOUNTNAME --sas-token ${BLOB_SAS_TOKEN:1:-1}
    fi
fi

exit 0



