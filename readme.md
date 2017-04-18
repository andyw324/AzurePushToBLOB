# README
The two bash script files provide a basic means to automate data file pushes from a server to a user defined Azure BLOB storage container within a user defined Azure Storage Account.

## Prerequsites
The scripts have the following dependencies:
* `monitor_folder_to_push_from.sh`
  * [inotify](https://linux.die.net/man/7/inotify)
  * Script calls `automate_push_to_blob.sh` and hence requires dependencies below
  
* `automate_push_to_blob.sh`
  * [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  
Other prerequisites are:
* A valid Azure Storage account with a BLOB container
* An Azure User / Service account with sufficient permissions to access the Azure Storage Account Keys and ability to create Shared Access Signature (SAS) tokens

## Scripted Process Steps
The `monitor_folder_to_push_from.sh` continuously monitors a specified folder (defined using the `--watch-dir` parameter tag) for new files, logging any new files or changes to the contents of the folder. When a file with a name matching the value passed using the `--complete-file` parameter tag is created and released, the following steps take place:
1. Remove the `--complete-file` from the `--watch-dir`
2. Create an Archive folder based on the current timestamp within the path passed using the `--archive-dir` parameter tag
3. Loop through each file within the `--watch-dir` directory and:
    1. Initiate file push to Azure BLOB storage via the `automate_push_to_blob.sh` script.
    2. Move file from the `--watch-dir` to the timestamp folder in the `--archive-dir`
4. Log each step of the process to `--log-file`

Below is an example of how to call the `monitor_folder_to_push_from.sh`:
>./monitor_folder_to_push_from.sh \\ \
--watch-dir /home/user/Documents/azureFileTransfer/incoming \\ \
--log-file /home/user/Documents/azureFileTransfer/watchlog.txt \\ \
--complete-file "complete.chk" \\ \
--archive-dir /home/user/Documents/azureFileTransfer/archive \\ \
--moveto-dir /home/user/Documents/azureFileTransfer/ \\ \
--upload-script /home/user/Documents/AzurePushToBLOB \\ \
--container "blob-container" \\ \
--account-name "storage-account-name" \\ \
--time-add "15 minute"

The `automate_push_to_blob.sh` pushes a single file (defined using `--upload-file`) to a specified BLOB (defined using `--blob-name`) within a Container (defined using `--container-name`) part of a Azure Storage Account (defined using `--account-name`). When run the following steps take place:
1. Check whether the Azure CLI has logged in with a valid account
2. Generate a SAS token with an expiry date/time 5 minutes from current time
3. Initiate file upload
4. Log all sdouts
