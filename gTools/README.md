# git Tools
This folder contains scripts to ease certain operations on the git environment.
- [git Tools](#git-tools)
  - [Setup GIT with SSH to use SSH keys](#setup-git-with-ssh-to-use-ssh-keys)
    - [Ubuntu](#ubuntu)
    - [Windows](#windows)
  - [Freeze a file](#freeze-a-file)
    - [Changing branch with skipped files involved](#changing-branch-with-skipped-files-involved)
  - [Git: Delete a branch local and remote](#git-delete-a-branch-local-and-remote)
  - [Github: Git Squash](#github-git-squash)
  - [Github: Merge two branches](#github-merge-two-branches)
  - [Github: Merge using git rebase](#github-merge-using-git-rebase)
  - [Github: Delete a tag and upgrade it to a later commit](#github-delete-a-tag-and-upgrade-it-to-a-later-commit)

## Setup GIT with SSH to use SSH keys
If the reference of the GIT to be used is a **git@** ref., you will be required to create and register a SSH certificate at the machine connecting to the git.  
### Ubuntu
Execute the following steps at an Ubuntu terminal:
1. Generate the certificate
    ```shell
    KEY_NAME=ed25519
    EMAIL=<yourEmail>
    ssh-keygen -t ed25519 -C $EMAIL -f ~/.ssh/$KEY_NAME
    # OR
    ssh-keygen -o -t rsa -C $EMAIL -f ~/.ssh/$KEY_NAME
    ```

2. Create a new SSH key at the SSH Keys page of your git server (here you have the links to some of the ssh management pages):  
   - **[git.\<YOURORGANIZATION\>.es](https://git.<YOURORGANIZATION>.es/-/user_settings/ssh_keys)**
   - [github](https://github.com/settings/keys)
   - ...  

    The new SSH form asks for the Key that is the content of the public certificate generated at step 1. To extract its content run:
    ```shell
    cat ~/.ssh/$KEY_NAME.pub
    # Output must be something similar to:
    ssh-ed25519 AAAAC3...olVN your_email@example.com
    ```
    Provide a title, a Usage type (default would sufice for normal git operations (Authentication & signing or Authentication key)) and at some git engines, the expiration date.

3. Add the private key to the authorized_keys at your ubuntu machine:
    ```shell
    ssh-add ~/.ssh/$KEY_NAME  
    ```

    If an error appears, you may need to activate the ssh-agent service:
    ```shell
    eval `ssh-agent -s`
    ```

4. Automatize the registration of the private key.  
Presious steps need to be added to the user **~/.bashrc** file to register the keys on each new terminal session (CLI session) created.
    ```shell
    vi ~/.bashrc
    # At the end of the file add the lines to start the agent and to register the keys:
      ...
      # Custom initialization
      eval `ssh-agent -s` > /dev/null
      echo Adding certificates to the ssh-agent...
      ssh-add ~/.ssh/<SSHFile-1>
      ...
      ssh-add ~/.ssh/<SSHFile-N>
    ```
5. Finally you can start working with your git repository using a git@ ref.
    ```shell
    git clone git@....git
    git remote set-url origin git@....git
    ```

6. If an error still appears on the `git clone git@git...` use SSH over HTTPS (port 443):
    ```shell
    git clone git@....git
    # If the following error appears:
    #     ssh: connect to host github.com port 22: Connection refused
    #   fatal: Could not read from remote repository.
    # Set up a SSH over HTTPS
    vi ~/.ssh/config
    # Add the following lines replacing the <SSHFile>
    #  Host github.com
    #    HostName ssh.github.com
    #    Port 443
    #    User git
    #    IdentityFile ~/.ssh/<SSHFile>

    chmod 600 ~/.ssh/config
    ssh -T git@github.com
    # The following message should appears
    # Hi username! You've successfully authenticated, but GitHub does not provide shell access.

    # Try the clonation again
    ```

### Windows
Execute the following steps at a Windows powershell terminal:
1. Generate the certificate
    ```shell
    $env:KEY_NAME="ed25519"
    $env:EMAIL="<yourEmail>"
    ssh-keygen -t ed25519 -C "$env:EMAIL" -f "$HOME/.ssh/$env:KEY_NAME"
    # OR
    ssh-keygen -o -t rsa -C $EMAIL -f ~/.ssh/$KEY_NAME
    ```

2. Create a new SSH key at the SSH Keys page of your git server (here you have the links to some of the ssh management pages):  
   - **[git.\<YOURORGANIZATION\>.es](https://git.<YOURORGANIZATION>.es/-/user_settings/ssh_keys)**
   - [github](https://github.com/settings/keys)
   - ...  

    The new SSH form asks for the Key that is the content of the public certificate generated at step 1. To extract its content run:
    ```shell
    cat $HOME/.ssh/$env:KEY_NAME.pub
    # Output must be something similar to:
    ssh-ed25519 AAAAC3...olVN your_email@example.com
    ```

    Provide a title, a Usage type (default would sufice for normal git operations (Authentication & signing or Authentication key)) and at some git engines, the expiration date.

3. Add the private key to the authorized_keys at your ubuntu machine:
    ```shell
    $env:CERT_FILE="$HOME/.ssh/$env:KEY_NAME"
    ssh-agent $env:CERT_FILE
      # The correct message should be something similar to:​
      Identity added: .$env:CERT_FILE​
    ```
4. Finally you can start working with your git repository using a git@ ref.
    ```shell
    git clone git@....git
    git remote set-url origin git@....git
    ```
    #### Potential errors
  - On Windows, the service `OpenSSH Authentication Agent` must be enabled:  
    ```shell
    #check the service status​
    Get-Service -Name ssh-agent​
      Status   Name               DisplayName​
      ------   ----               -----------​
      Running  ssh-agent          OpenSSH Authentication Agent​
    ```
    
    If the agent is not running it has to be set to automatically start (next operation requires elevated permissions):
    
    ```shell
    #To set its start as automatic (requires admin permission):​
    Get-Service -Name ssh-agent | Set-Service -StartupType Automatic​
    ```

    ```shell
    #To verify the service 'OpenSSH Authentication Agent' status from the Windows service application look for it at the:
    services.msc​
    ```
  - Errors regarding the permissions granted to the ssh key files.  
    ```shell
    # Permissions for $env:CERT_FILE are too open
    cd $env:USERPROFILE\.ssh ​
    icacls $env:CERT_FILE /inheritance:r​
    icacls $env:CERT_FILE /grant:r "$env:USERNAME:(F)“ #if it fails, replace $env:USERNAME by its value e.g. cgonzalez​
    icacls $env:CERT_FILE /remove "Administrators" "SYSTEM" "Users“​
    icacls $env:CERT_FILE ​
    # Rerun the step 3
    ssh-agent $env:CERT_FILE
      # The correct message should be something similar to:​
      Identity added: .$env:CERT_FILE​
    ```
## Freeze a file
The gTools/gFreeze.sh command implements this behaviour.  
See [this article from medium](https://medium.com/@adi.ashour/dont-git-angry-skip-in-worktree-e9c77dec9d15), [git assume unchanged skip worktree](https://www.baeldung.com/ops/git-assume-unchanged-skip-worktree)  

If you have a file commited at git that should not have further changes commited, it has to be 'skipped'. To mark the File as Skipped (skip-worktree) to stop tracking changes to that file while keeping it in the repository run these commands at the git folder:
```shell
git update-index --skip-worktree <your-file>  
# OR 
git update-index --assume-unchanged <your-file> # Not recommended

# The --skip-worktree flag is more suitable than --assume-unchanged for configuration or files that you want to keep locally modified but not include in future commits.
```

To undo the operation just run:
```shell
git update-index --no-skip-worktree <your-file>
OR
git update-index --no-assume-unchanged <your-file> # Not recommended
```

### Changing branch with skipped files involved
If the skipped file differs between the current branch and the target branch, an error like "Please commit your changes or stash them before you switch branches." will appear cancelling the switching of branch. To solve the issue, follow these steps:  
```shell
# Unset the --skip-worktree Bit
# gFreeze -u
# Stash Your Changes
# git stash push -m "Stashing changes in [file-path]" [file-path]
gFreeze -stash
# Switch Branches
git checkout $NEWBRANCH
# Reapply the --skip-worktree
# git stash pop
# Reapply Stashed Changes
# gFreeze
gFreeze -unstash
```
## Git: Delete a branch local and remote
```shell
# To view the git info, you can run the command 'gInfo'
REMOTEGIT=https://github.com/$USER/${REPOSITORYNAME}.git
# Remove the remote branch
git push $REMOTEGIT --delete $BRANCHNAME
# Remove the local branch
git branch -d $BRANCHNAME
```

## Github: Git Squash
Taken from [StackOverflow: How do I squash my last N commits together](https://stackoverflow.com/questions/5189560/how-do-i-squash-my-last-n-commits-together)
Git squash is used to, while keeping the changes, get rid of not relevant comments in the commits squashing several of them into just one commit summarizing the changes of all the squashed commits.  
The scenario is that at this point you are at your altBranch with a number of commits and you want to replace the X latest ones by just one
- Review the latest changes
```shell
git log --oneline
    6fb28f6 (HEAD -> altBranch, tag: step04, origin/altBranch) Use Admin API to manage routes
    f405746 (tag: step03) Step03: Deploy a new route via the altBranch.yaml file
    a0175d9 (tag: step02) step02: Deploy a functional version of altBranch
    7488c0f (tag: step01) step01 of altBranch deployment
    5ab8044 helms/altBranch empty certificates added
    3a42eb4 (origin/main, origin/HEAD, main) Initial commit
```
- We will squash the latest 5 latest commits (5 in this example)  
```shell
BRANCH_NAME=altBranch
git checkout $BRANCH_NAME
git reset --soft HEAD~5
# All the modified files in the latests 5 commits are moved to the stage area waiting to be commited
git commit -m "helms/altBranch empty certificates added"
git push --force-with-lease origin $BRANCH_NAME
# After committing, check the new commit's structure:
git log --oneline
```

## Github: Merge two branches

```shell
# The scenario is that at this point you are at your altBranch with a number of commits that have to be merged into the main branch.
# Downloads latest change from main
DST_BRANCH=main
SRC_BRANCH=altBranch
git checkout $DST_BRANCH
git pull
git checkout $SRC_BRANCH
git pull
# First of all merges the dest into the src to avoid problems on the dest
git merge --no-ff $DST_BRANCH
# Solve any potential conflict and commit it if necessary.
git commit -m "message if it is necessary to commit some changes"
git push
# If an error appears, you can try
git push --force

git checkout $DST_BRANCH
git merge --no-ff $SRC_BRANCH
# Solve any potential conflict and commit it if necessary.
git commit -m "message if it is necessary to commit some changes"
git push
# If an error appears, you can try
git push --force
git push --force-with-lease
```


## Github: Merge using git rebase
Taken from [The Modern Coder-Git rebase](https://www.youtube.com/watch?v=f1wnYdLEpgI)  
He defends the point that rebase is for complex gits cleaner that merging.  
It is dangerous when multiple people is commiting to the main branch.   
NOTE: Here _master_ is just to ilustrate the example. I used _altBranch_ as the branch to rebase into _master_

```shell
# The scenario is that at this point you are at your altBranch with a number of commits.
# Downloads latest change from main
DST_BRANCH=main
SRC_BRANCH=altBranch
git checkout $DST_BRANCH
git pull
git checkout $SRC_BRANCH
git rebase $DST_BRANCH
# Solve any potential conflict and commit it.
git checkout $DST_BRANCH
git rebase $SRC_BRANCH
# No conflicts should appear
git push
# If an error appears, you can try
git push --force
git push --force-with-lease
```

## Github: Delete a tag and upgrade it to a later commit
First section on the scripts deletes the tag, and then, it is reassigned to the most recent commit.
```shell
# Taken from https://stackoverflow.com/questions/8044583/how-can-i-move-a-tag-on-a-git-branch-to-a-different-commit

# Take the list of remote tags
git ls-remote --tags
TAG=<tagName>
# Delete the desired tag on any remote before you push
git push origin :refs/tags/$TAG

# Delete local tag (if it exists)
git tag -d $TAG

# Replace the tag to reference the most recent commit
NEWTAG=<newTagName>
git tag -fa $NEWTAG
# or
git tag -f $NEWTAG -m <tagComment>

# Push the tag to the remote origin
git push origin --tags
# Maybe it is required to specify the --force parameter
git push origin --force $NEWTAG
```