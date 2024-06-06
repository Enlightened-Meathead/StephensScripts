#!/bin/bash
## This is a simple script that will take a designated directory (My peronal case being my obsidian vault) and archive, compress, then encrypt the directory into a back up that gets uploaded to github 

# Your directory to backup
FOLDER_TO_ENCRYPT="/home/stephen/StephensVault/"
# The name you would like the backup to be
ARCHIVE_NAME="StephensVault_backup.tar.gz"
ENCRYPTED_ARCHIVE_NAME="${ARCHIVE_NAME}.gpg"
GIT_COMMIT_MESSAGE="Encrypted backup $(date +'%Y-%m-%d %H:%M:%S')"
# The location of the repo you would like to have as centralized git repo to push your backups from
BACKUP_REPO_PATH="/home/stephen/Backups/VaultBackup/"
GIT_REMOTE="origin"
GIT_BRANCH="main"
GIT_URL="https://github.com/Enlightened-Meathead/VaultBackup"
GPG_PASS_FILE="${BACKUP_REPO_PATH}.gpg_passphrase"
GIT_BACKUP_TOKEN="${BACKUP_REPO_PATH}.git_backup_token"

# If the user supplied an access token, push to the git repo with that
if [ -f "$GIT_BACKUP_TOKEN" ]; then
  GIT_PUSH_URL="https://$(cat "$GIT_BACKUP_TOKEN")@github.com/Enlightened-Meathead/VaultBackup"
fi

# Ensure the pass file exists and is readable
if [ ! -f "$GPG_PASS_FILE" ]; then
  echo "Error: Your GPG_PASS_FILE does not exist or the path set in this script is incorrect"
  exit 1
fi

cd "$FOLDER_TO_ENCRYPT"
GPG_PASSPHRASE=$(cat "$GPG_PASS_FILE")
tar -czvf "$ARCHIVE_NAME" "$FOLDER_TO_ENCRYPT"
echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 "$ARCHIVE_NAME"

# If the local directory path doesnt exit, throw an error
if [ ! -d "$BACKUP_REPO_PATH" ]; then
  echo "The target directory to backup into does not exist. Please enter a valid path or create a directory"
  exit 1
fi

# If the directory to back up to exists and is a git repo, then cd to that directory and finish the script
if [ -d "$BACKUP_REPO_PATH/.git" ]; then
  mv "$ENCRYPTED_ARCHIVE_NAME" "$BACKUP_REPO_PATH"
else
  git clone "$GIT_URL" "$BACKUP_REPO_PATH"
  if [$? -ne 0 ]; then
    echo "The target Git repository does not exist or is mistyped. Please create a remote Git repo and specify a valid url to place the backup in the config variables at the start of this script."
    exit 1
  fi
  mv "$ENCRYPTED_ARCHIVE_NAME" "$REPO_PATH"
fi

cd "$BACKUP_REPO_PATH"
git add "$ENCRYPTED_ARCHIVE_NAME"
git commit -m "$GIT_COMMIT_MESSAGE"

# If the git repo does exist, but the user hasn't setup set the branch and origin, then set it up. Once done, push it to the repo
if [ -n "${GIT_PUSH_URL+1}" ]; then
  git push "$GIT_PUSH_URL" "$GIT_BRANCH"
elif [ "$(git remote get-url origin)" = "$GIT_URL" ]; then
  git push -u "$GIT_REMOTE" "$GIT_BRANCH"
else
  git branch -M "$GIT_BRANCH"
  git remote add origin "$GIT_URL"
  git push -u "$GIT_REMOTE" "$GIT_BRANCH"
fi

# Remove the encrypted archive after the push has finished
rm "$FOLDER_TO_ENCRYPT$ARCHIVE_NAME"
rm "$BACKUP_REPO_PATH$ENCRYPTED_ARCHIVE_NAME"
