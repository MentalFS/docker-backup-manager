# docker-backup-manager
A Docker image for [Backup-Manager] based on the Debian package.

This image is supposed to backup Docker volumes from other containers. It will stay running and executes *backup-manager* daily.

The Volumes can be mounted under `/VOLUME/<Volume Name>`, or at a place configured with the settings below.


## Volumes

| Path            |                                                                               |
|-----------------|--------------------------------------------------------------------------------
| `/var/archives` | Target for the backup archives. Will contain a *.temp* and *.anacron* folder. |


## Download

```
docker pull ghcr.io/mentalfs/backup-manager
```

## Example

```bash
docker run --name backup-manager \
  -e BM_REPOSITORY_USER=1000 \
  -e BM_REPOSITORY_GROUP=1000 \
  -v /path/to/my/archives:/var/archives \
  -v my-first-volume:/VOLUME/my-first-volume:ro \
  -v my-second-volume:/VOLUME/my-second-volume:ro \
  -d ghcr.io/mentalfs/backup-manager
```


## Supported settings

| Environment Variable              | Default                 |                                                                               |
|-----------------------------------|-------------------------|-------------------------------------------------------------------------------|
| `CRON_SCHEDULE`                   | `@hourly`               | [Cron expression] for backup execution, will still only run once per day      |
| `BM_REPOSITORY_USER`              | `root`                  | The owner of the archive (UID numbers will work), will have read/write access |
| `BM_REPOSITORY_GROUP`             | `root`                  | The group of the archive (GID numbers will work), will have read access only  |
| `BM_REPOSITORY_RECURSIVEPURGE`    | `false`                 | Do you want to purge directories under `BM_REPOSITORY_ROOT`? (*true*/*false*) |
| `BM_ARCHIVE_METHOD`               | `tarball-incremental`   | The backup method to use (*tarball* or *tarball-imcremental*)                 |
| `BM_ARCHIVE_PREFIX`               | `DOCKER`                | Prefix of every archive on that box                                           |
| `BM_ARCHIVE_PURGEDUPS`            | `true`                  | Do you want to replace duplicates by symlinks?                                |
| `BM_ARCHIVE_STRICTPURGE`          | `true`                  | Purge only archives built with `BM_ARCHIVE_PREFIX`? (*true*/*false*)          |
| `BM_ARCHIVE_TTL`                  | `14`                    | Number of days we have to keep an archive (Time To Live)                      |
| `BM_ENCRYPTION_METHOD`            | `none`                  | Encryption method to use (*gpg* or *none* for no encryption)                  |
| `BM_ENCRYPTION_RECIPIENT`         | ` `                     | The GPG ID used for encryption of archives                                    |
| `BM_TARBALL_BLACKLIST`            | ` `                     | Files to exclude when generating tarballs                                     |
| `BM_TARBALL_DIRECTORIES`          | `/VOLUME/*`             | Targets to backup (may contain wildcards, but no spaces)                      |
| `BM_TARBALL_FILETYPE`             | `tar.gz`                | Type of archives (*tar*, *tar.gz*, *tar.bz2*, *tar.xz*, *tar.lzma*)           |
| `BM_TARBALL_NAMEFORMAT`           | `long`                  | Archive filename format (*long* or *short*)                                   |
| `BM_TARBALLINC_MASTERDATETYPE`    | `weekly`                | Which frequency to use for the master tarball? (*weekly*, *monthly*)          |
| `BM_TARBALLINC_MASTERDATEVALUE`   | `1`                     | Number of the day, in the week/month when master tarballs should be made      |
| `BM_UPLOAD_METHOD`                | `none`                  | Method to use for uploading archives (*scp*, *ssh-gpg*, *rsync* or *none*)    |
| `BM_UPLOAD_SSH_HOSTS`             | ` `                     | SSH hosts for upload                                                          |
| `BM_UPLOAD_SSH_PORT`              | ` `                     | Port to use for SSH connections (leave blank for default one)                 |
| `BM_UPLOAD_SSH_USER`              | ` `                     | The user to use for the SSH connections/transfers                             |
| `BM_UPLOAD_SSH_KEY`               | `/etc/ssh/id_rsa`       | Path to the private key to use for SSH (**must be mounted if used**)          |
| `BM_UPLOAD_SSH_DESTINATION`       | ` `                     | Destination (path) for SSH uploads                                            |
| `BM_UPLOAD_SSH_PURGE`             | `true`                  | Purge archives on SSH hosts before uploading? (*true*/*false*)                |
| `BM_UPLOAD_SSH_TTL`               | *BM_ARCHIVE_TTL*        | Number of days we have to keep an archive on SSH server (Time To Live)        |
| `BM_UPLOAD_SSHGPG_RECIPIENT`      | ` `                     | The GPG ID used for encryption of SSH uploads (method *ssh-gpg*)              |
| `BM_UPLOAD_RSYNC_HOSTS`           | ` `                     | rsync hosts for upload                                                        |
| `BM_UPLOAD_RSYNC_DESTINATION`     | ` `                     | Destination (path) for rsync uploads                                          |
| `BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT` | ` `                     | Bandwidth limit for rsync uploads (Example: 32M, 1024K, ...)                  |
| `BM_UPLOAD_RSYNC_BLACKLIST`       | ` `                     | Files to exclude during rsync uploads                                         |
| `BM_UPLOAD_RSYNC_DIRECTORIES`     | `/var/archives/`        | Which directories should be backed up with rsync                              |
| `BM_UPLOAD_RSYNC_EXTRA_OPTIONS`   | `--delete`              | Extra options for rsync                                                       |
| `GNUPGIMPORT`                     | `/etc/gnupg/import.gpg` | GPG keys(s) to import on startup (if they exist)                              |
| `TZ`                              | `Europe/Berlin`         | Timezone from [/usr/share/zoneinfo]                                           |


## Notes

* Backups will be retried according to `CRON_SCHEDULE` when a step fails (including uploads).
* GPG encryption will only work with *tar*, *tar.gz*, *tar.bz2* formats.
* `BM_UPLOAD_METHOD` *ssh-gpg* does not support `BM_UPLOAD_SSH_PURGE` and `BM_UPLOAD_SSH_TTL`.
* You can specify multiple hosts for uploads, but all will use the same authentication, port and destination folder.
* SSH passwords or keys with password are not supported.
* rsync shares multiple settings with SSH, including the authentication.
* The [upstream project] seems to be stale, so this image uses the Debian package which has a few patches.

[Backup-Manager]: https://packages.debian.org/stable/backup-manager
[upstream project]: https://github.com/sukria/Backup-Manager
[Cron expression]: https://manpages.debian.org/stable/cron/crontab.5.en.html
[/usr/share/zoneinfo]: https://packages.debian.org/stable/all/tzdata/filelist
