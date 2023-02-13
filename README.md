# docker-backup-manager
A Docker image for [Backup-Manager](https://packages.debian.org/stable/backup-manager).

This image is supposed to backup Docker volumes from other containers. It will stay running and executes *backup-manager* daily.

The Volumes can be mounted under `/VOLUME/<Volume Name>`, or at a place configured with the settings below.


## User

By default, this image will run as `backup` user. Depending on the volumes it might be neccessary to start the container as `root`.
Users with UID and GID from 900 to 1100 have also been created. Additional users will have to be created with a Dockerfile.


## Volumes

| Path            |                                                                |
|-----------------|-----------------------------------------------------------------
| `/var/archives` | Target for the backup archives. Will contain a *.temp* folder. |


## Download

```
docker pull ghcr.io/mentalfs/backup-manager
```

## Example

```bash
docker run --user 1000:backup --name backup-manager \
  -v /path/to/my/archives:/var/archives \
  -v my-first-volume:/VOLUME/my-first-volume \
  -v my-second-volume:/VOLUME/my-second-volume \
  -d ghcr.io/mentalfs/backup-manager
```


## Supported settings

| Environment Variable              | Default               |                                                                                             |
|-----------------------------------|-----------------------|---------------------------------------------------------------------------------------------|
| `BM_CRON`                         | `0 3 * * *` *(03:00)* | [Cron expression](https://manpages.debian.org/stable/manpages-de/crontab.5) for backups     |
| `BM_REPOSITORY_USER`              | *container user*      | The owner of the archive files (UID numbers will work), will have read & write access       |
| `BM_REPOSITORY_GROUP`             | *container group*     | The group of the archive files (GID numbers will work), will have read access only          |
| `BM_REPOSITORY_RECURSIVEPURGE`    | `false`               | Do you want to purge directories under `BM_REPOSITORY_ROOT`? (*true*/*false*)               |
| `BM_ARCHIVE_METHOD`               | `tarball-incremental` | The backup method to use (*tarball* or *tarball-imcremental*)                               |
| `BM_ARCHIVE_PREFIX`               | `DOCKER`              | Prefix of every archive on that box                                                         |
| `BM_ARCHIVE_PURGEDUPS`            | `true`                | Do you want to replace duplicates by symlinks?                                              |
| `BM_ARCHIVE_STRICTPURGE`          | `true`                | Should we purge only archives built with `BM_ARCHIVE_PREFIX`? (*true*/*false*)              |
| `BM_ARCHIVE_TTL`                  | `14`                  | Number of days we have to keep an archive (Time To Live)                                    |
| `BM_ENCRYPTION_METHOD`            | `false`               | Encryption method to use (*gpg* or *false* for no encryption)                               |
| `BM_ENCRYPTION_RECIPIENT`         | ` `                   | The GPG ID used for encryption of archives                                                  |
| `BM_TARBALL_BLACKLIST`            | ` `                   | Files to exclude when generating tarballs                                                   |
| `BM_TARBALL_DIRECTORIES`          | `/VOLUME/*`           | Targets to backup (may contain wildcards, but no spaces)                                    |
| `BM_TARBALL_FILETYPE`             | `tar.gz`              | Type of archives (*tar*, *tar.gz*, *tar.bz2*, *tar.xz*, *tar.lzma*)                         |
| `BM_TARBALL_NAMEFORMAT`           | `long`                | Archive filename format (*long* or *short*)                                                 |
| `BM_TARBALLINC_MASTERDATETYPE`    | `weekly`              | Which frequency to use for the master tarball? (*weekly*, *monthly*)                        |
| `BM_TARBALLINC_MASTERDATEVALUE`   | `1`                   | Number of the day, in the week/month when master tarballs should be made                    |
| `BM_UPLOAD_METHOD`                | `none`                | Method to use for uploading archives (*scp*, *ssh-gpg*, *rsync* or *none*)                  |
| `BM_UPLOAD_SSH_HOSTS`             | ` `                   | SSH hosts for upload                                                                        |
| `BM_UPLOAD_SSH_PORT`              | ` `                   | Port to use for SSH connections (leave blank for default one)                               |
| `BM_UPLOAD_SSH_USER`              | ` `                   | The user to use for the SSH connections/transfers                                           |
| `BM_UPLOAD_SSH_KEY`               | `/etc/ssh/id_rsa`     | Path to the private key to use for opening the connection (**must be mounted if used**)     |
| `BM_UPLOAD_SSH_DESTINATION`       | ` `                   | Destination (path) for SSH uploads                                                          |
| `BM_UPLOAD_SSH_PURGE`             | `true`                | Purge archives on SSH hosts before uploading? (*true*/*false*)                              |
| `BM_UPLOAD_SSH_TTL`               | *BM_ARCHIVE_TTL*      | Number of days we have to keep an archive on SSH server (Time To Live)                      |
| `BM_UPLOAD_SSHGPG_RECIPIENT`      | ` `                   | The GPG ID used for encryption of SSH uploads (method *ssh-gpg*)                            |
| `BM_UPLOAD_RSYNC_HOSTS`           | ` `                   | rsync hosts for upload                                                                      |
| `BM_UPLOAD_RSYNC_DESTINATION`     | ` `                   | Destination (path) for rsync uploads                                                        |
| `BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT` | ` `                   | Bandwidth limit for rsync uploads (Example: 32M, 1024K, ...)                                |
| `BM_UPLOAD_RSYNC_BLACKLIST`       | ` `                   | Files to exclude during rsync uploads                                                       |
| `BM_UPLOAD_RSYNC_DIRECTORIES`     | `/var/archives`       | Which directories should be backed up with rsync                                            |
| `GNUPGHOME`                       | `/etc/gnupg`          | GPG configuration folder for encryption (**must be mounted if used**)                       |
| `LOGFILE`                         | `syslog`              | Which logfile in */var/log* to output in the container (*syslog*, *messages* or *user.log*) |
| `TZ`                              | `Europe/Berlin`       | Timezone from [/usr/share/zoneinfo](https://packages.debian.org/stable/all/tzdata/filelist) |


## Notes

* GPG encryption will only work with *tar*, *tar.gz*, *tar.bz2* formats.
* You can specify multiple hosts for upload, but all will use the same authentication, port and destination folder.
* SSH passwords or keys with password are not supported.
* SSH will only try to upload the archives once. This might make rsync a viable option for instable connections.
* rsync shares multiple settings with SSH, including the authentication.
* rsync will sync the entire folders including deletions and it's possible to sync other folders than the archives.
* FTP uploads have unresolved critical bugs for over 5 years and thus are not supported in this image.
* **The project seems to be stale**, but it mostly relies on bash and CLI tools with a stable interface.

## Alternatives

Since *Backup-Manager* apparently isn't maintained anymore, the following projects might be worth a look:
* [BorgBackup](https://packages.debian.org/stable/borgbackup)
* [Backupninja](https://packages.debian.org/stable/backupninja) & [Duplicity](https://packages.debian.org/stable/duplicity)
