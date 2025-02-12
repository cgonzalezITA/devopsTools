# git Tools
This folder contains scripts to ease certain operations on the git environment.
- [git Tools](#git-tools)
  - [Creating a git keypair certificate](#creating-a-git-keypair-certificate)
  - [Commit with comments](#commit-with-comments)
  - [Freeze a file](#freeze-a-file)
    - [Changing branch with skipped files involved](#changing-branch-with-skipped-files-involved)
  - [Git: Delete a branch local and remote](#git-delete-a-branch-local-and-remote)
  - [Github: Git Squash](#github-git-squash)
  - [Github: Merge two branches](#github-merge-two-branches)
  - [Github: Merge using git rebase](#github-merge-using-git-rebase)
  - [Github: Delete a tag and upgrade it to a later commit](#github-delete-a-tag-and-upgrade-it-to-a-later-commit)

## Creating a git keypair certificate
If the remote URL is a **git@** ref. you will be required to have a git keypair certificate setup (the symptom is that you will be asked for the git password that does not match the user password). You will have to add hence a keypair certificate to your machine to connect to the git.  
Execute the following steps at an Ubuntu machine in which the git has to be cloned (For windows environments see the [presentation de metología del dpto ITA BDSC -git sin passwords-](https://feditmpsa.sharepoint.com/:p:/s/TD_BD_Sistemas_Cognitivos2/EUsBoj-0XsBFjQ5AVnV5UJABpygh1x9vMnwkAfGIddkt_Q?e=55cl18)):  
1. If your remote URL is still a **http://...git** ref and you want to replace it by its **git@...git*** remote URL:
  ```shell
  git remote -v # To view the remote URL
  origin  https://github.com/cgonzalezITA/devopsTools.git (fetch)
  origin  https://github.com/cgonzalezITA/devopsTools.git (push)
  git remote set-url origin git@github.com/cgonzalezITA/devopsTools.git
  ```
2. (Linux & Windows) Generate the certificate
```shell
KEY_NAME=ed25519
EMAIL=<yourEmail>
ssh-keygen -t ed25519 -C $EMAIL -f ~/.ssh/$KEY_NAME
# OR
ssh-keygen -o -t rsa -C $EMAIL -f ~/.ssh/$KEY_NAME
```

1. Copy the public certificate to the SSH Keys page of your git server (here you have the links to some of the ssh management pages):  
- **[git.itainnova.es](https://git.itainnova.es/-/user_settings/ssh_keys)**
- [github](https://github.com/settings/keys)
- ...
```shell
# (Linux) To extract the public key run -replacing the key file <id_$KEY_NAME.pub> by the generated one at step 1):      
cat ~/.ssh/$KEY_NAME.pub
# Output must be something similar to:
ssh-$KEY_NAME AAAAC3...olVN your_email@example.com
```

1. (Linux & Windows) Add the private key to the authorizes_keys in your working machine (the key file <id_$KEY_NAME.pub> should be replaced by the just generated one):
```shell
ssh-add ~/.ssh/$KEY_NAME  
```

If an error appears, you may need to activate the ssh-agent service:

```shell
eval `ssh-agent -s`
```

**NOTE**: Keypair generation for windows is fully described at [presentation de metología del dpto ITA BDSC -git sin passwords-](https://feditmpsa.sharepoint.com/:p:/s/TD_BD_Sistemas_Cognitivos2/EUsBoj-0XsBFjQ5AVnV5UJABpygh1x9vMnwkAfGIddkt_Q?e=55cl18) including Windows setup and snapshots.  

4. Automatize the registration of the private keys  
Presious steps need to be added to the user **~/.bashrc** file to register the keys on each new terminal session (CLI session)
```shell
vi ~/.bashrc
# At the end of the file add the lines to start the agent and to register the keys:
  ...
  # Custom initialization
  eval `ssh-agent -s` > /dev/null
  echo Adding certificates to the ssh-agent...
  ssh-add ~/.ssh/id_$KEY_NAME-key1
  ...
  ssh-add ~/.ssh/id_$KEY_NAME-keyN
```

## Commit with comments
To simplify the commit, after all the changes have been added, just execute the command:
```shell
# USAGE: gCommit.sh [-h] [-s <submodulePath>] <comment1 (with quotes ")> [<comment2 (with quotes ")>]
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