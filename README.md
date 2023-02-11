# docker-backup-manager
A Docker image for [Backup-Manager](https://packages.debian.org/stable/backup-manager)

This image is supposed to backup Docker volumes from other containers. It will stay running and executes *backup-manager* daily.

The Volumes can be mounted under `/VOLUME/<Volume Name>`, or at a place configured with the settings below.


## Volumes

| Path            |                                                                |
|-----------------|-----------------------------------------------------------------
| `/var/archives` | Target for the backup archives. Will contain a *.temp* folder. |
| `/root/.gnupg`  | Optional, GPG configuration folder for encryption              |


## Supported settings

| Environment Variable              | Default               |                                                                                             |
|-----------------------------------|-----------------------|---------------------------------------------------------------------------------------------|
| `BM_CRON`                         | `0 3 * * *`           | Cron expression when backup-manager should run (defaults to 3:00 every morning)             |
| `BM_ARCHIVE_METHOD`               | `tarball-incremental` | The backup method to use (*tarball* or *tarball-imcremental*)                               |
| `BM_ARCHIVE_PREFIX`               | `DOCKER`              | Prefix of every archive on that box                                                         |
| `BM_ARCHIVE_PURGEDUPS`            | `true`                | Do you want to replace duplicates by symlinks?                                              |
| `BM_ARCHIVE_STRICTPURGE`          | `true`                | Should we purge only archives built with `BM_ARCHIVE_PREFIX`? (*true*/*false*)              |
| `BM_ARCHIVE_TTL`                  | `14`                  | Number of days we have to keep an archive (Time To Live)                                    |
| `BM_ENCRYPTION_METHOD`            | `false`               | Encryption method to use (*gpg* or *false* for no encryption)                               |
| `BM_ENCRYPTION_RECIPIENT`         | ` `                   | The GPG ID used for encryption of archives                                                  |
| `BM_REPOSITORY_RECURSIVEPURGE`    | `false`               | Do you want to purge directories under `BM_REPOSITORY_ROOT`? (*true*/*false*)               |
| `BM_TARBALL_BLACKLIST`            | ` `                   | Files to exclude when generating tarballs                                                   |
| `BM_TARBALL_DIRECTORIES`          | `/VOLUME/*`           | Targets to backup (may contain wildcards, but no spaces)                                    |
| `BM_TARBALL_FILETYPE`             | `tar.gz`              | Type of archives (*tar*, *tar.gz*, *tar.bz2*, *tar.xz*, *tar.lzma*, *dar*, *zip*)           |
| `BM_TARBALL_NAMEFORMAT`           | `long`                | Archive filename format (*long* or *short*)                                                 |
| `BM_TARBALL_SLICESIZE`            | `1000M`               | With the "dar" filetype, you can choose a maximum slice limit.                              |
| `BM_TARBALLINC_MASTERDATETYPE`    | `weekly`              | Which frequency to use for the master tarball? (*weekly*, *monthly*)                        |
| `BM_TARBALLINC_MASTERDATEVALUE`   | `1`                   | Number of the day, in the week/month when master tarballs should be made                    |
| `BM_UPLOAD_METHOD`                | `none`                | Method to use for uploading archives (*scp*, *ssh-gpg*, *ftp*, *rsync* or *none*)           |
| `BM_UPLOAD_SSH_HOSTS`             | ` `                   | SSH hosts for upload                                                                        |
| `BM_UPLOAD_SSH_PORT`              | ` `                   | Port to use for SSH connections (leave blank for default one)                               |
| `BM_UPLOAD_SSH_USER`              | ` `                   | The user to use for the SSH connections/transfers                                           |
| `BM_UPLOAD_SSH_KEY`               | `/root/.ssh/id_rsa`   | Path to the private key to use for opening the connection (must be mounted)                 |
| `BM_UPLOAD_SSH_DESTINATION`       | ` `                   | Destination (path) for SSH uploads                                                          |
| `BM_UPLOAD_SSH_PURGE`             | `false`               | Purge archives on SSH hosts before uploading? (*true*/*false*)                              |
| `BM_UPLOAD_SSH_TTL`               | *BM_ARCHIVE_TTL*      | Number of days we have to keep an archive on SSH server (Time To Live)                      |
| `BM_UPLOAD_SSHGPG_RECIPIENT`      | ` `                   | The GPG ID used for encryption of SSH uploads (method *ssh-gpg*)                            |
| `BM_UPLOAD_RSYNC_HOSTS`           | ` `                   | rsync hosts for upload                                                                      |
| `BM_UPLOAD_RSYNC_DESTINATION`     | ` `                   | Destination (path) for rsync uploads                                                        |
| `BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT` | ` `                   | Bandwidth limit for rsync uploads (Example: 32M, 1024K, ...)                                |
| `BM_UPLOAD_RSYNC_BLACKLIST`       | ` `                   | Files to exclude during rsync uploads                                                       |
| `BM_UPLOAD_RSYNC_DIRECTORIES`     | `/var/archives`       | Which directories should be backed up with rsync                                            |
| `BM_UPLOAD_FTP_HOSTS`             | ` `                   | FTP hosts for upload                                                                        |
| `BM_UPLOAD_FTP_USER`              | ` `                   | The user to use for the FTP connections/transfers                                           |
| `BM_UPLOAD_FTP_PASSWORD`          | ` `                   | The FTP user's password                                                                     |
| `BM_UPLOAD_FTP_DESTINATION`       | ` `                   | Destination (path) for FTP uploads                                                          |
| `BM_UPLOAD_FTP_PURGE`             | `false`               | Purge archives on FTP hosts before uploading? (*true*/*false*)                              |
| `BM_UPLOAD_FTP_TTL`               | *BM_ARCHIVE_TTL*      | Number of days we have to keep an archive on FTP server (Time To Live)                      |
| `TZ`                              | `Europe/Berlin`       | Timezone from [/usr/share/zoneinfo](https://packages.debian.org/stable/all/tzdata/filelist) |


## Notes

* To use encryption, a GPG configuration will have to be mounted at `/root/.gnupg`.
* GPG encryption will only work with *tar*, *tar.gz*, *tar.bz2* formats.
* You can specify multiple hosts for upload, but all will use the same authentication, port and destination folder.
* SSH passwords or keys with password are not supported.
* SSH and FTP will only try to upload the archives once. This might make rsync a viable option for instable connections.
* rsync shares multiple settings with SSH, including the authentication.
* rsync will sync the entire folders including deletions and it's possible to sync other folders than the archives.
* The FTP port can't be changed.
* Only unencrypted FTP is supported, be careful. ([bug report](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=672236))
* **The project seems to be stale**, but it mostly relies on bash and CLI tools with a stable interface.
