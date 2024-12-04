# git Tools
This folder contains scripts to ease certain operations on the git environment.
- [git Tools](#git-tools)
  - [Creating a git keypair certificate](#creating-a-git-keypair-certificate)
  - [Commit with comments](#commit-with-comments)
  - [Freeze a file](#freeze-a-file)
    - [Changing branch with skipped files involved](#changing-branch-with-skipped-files-involved)
  - [Github: Git Squash](#github-git-squash)
  - [Github: Merge using git rebase](#github-merge-using-git-rebase)
  - [Github: Upgrade tag to a later commit](#github-upgrade-tag-to-a-later-commit)

## Creating a git keypair certificate
If opting for the **git@** ref. you will be required to have a git keypair certificate setup (the symptom is that you will be asked for the git password that does not match the user password). You will have to add hence a keypair certificate to your machine to connect to the git.  
Execute the following steps at an Ubuntu machine in which the git has to be cloned (For windows environments see the [presentation de metología del dpto ITA BDSC -git sin passwords-](https://feditmpsa.sharepoint.com/:p:/s/TD_BD_Sistemas_Cognitivos2/EUsBoj-0XsBFjQ5AVnV5UJABpygh1x9vMnwkAfGIddkt_Q?e=55cl18)):
1. (Linux & Windows) Generate the certificate
```shell
KEY_NAME=ed25519
EMAIL=<yourEmail>
ssh-keygen -t ed25519 -C $EMAIL -f ~/.ssh/$KEY_NAME
# OR
ssh-keygen -o -t rsa -C $EMAIL -f ~/.ssh/$KEY_NAME
```

2. Copy the public certificate to the SSH Keys page of your git server (here you have the links to some of the ssh management pages):  
- **[git.itainnova.es](https://git.itainnova.es/-/user_settings/ssh_keys)**
- [github](https://github.com/settings/keys)
- ...
```shell
# (Linux) To extract the public key run -replacing the key file <id_$KEY_NAME.pub> by the generated one at step 1):      
cat ~/.ssh/$KEY_NAME.pub
# Output must be something similar to:
ssh-$KEY_NAME AAAAC3...olVN your_email@example.com
```

3. (Linux & Windows) Add the private key to the authorizes_keys in your working machine (the key file <id_$KEY_NAME.pub> should be replaced by the just generated one):
> ssh-add ~/.ssh/$KEY_NAME  

If an error appears, you may need to activate the ssh-agent service:
> eval `ssh-agent -s`

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

## Github: Git Squash
Taken from [The Modern Coder-Git squash](https://www.youtube.com/watch?v=V5KrD7CmO4o)
Git squash is used to while keeping the changes, get rid of not relevant comments in the commits replacing several commits by just one commit sumarizing the changes of all the squashed commits.  
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
- We will squash the latest 5 latest commits   
```shell
git rebase -i HEAD~5
  # At this point a nano editor opens showing the pick (use commit) besides comments describing the possible operations (here we are to use just squash): 
  pick 5ab8044 helms/altBranch empty certificates added
  pick 7488c0f step01 of altBranch deployment
  pick a0175d9 step02: Deploy a functional version of altBranch
  pick f405746 Step03: Deploy a new route via the altBranch.yaml file
  pick 6fb28f6 Use Admin API to manage routes

  # Rebase 3a42eb4..6fb28f6 onto f405746 (5 commands)
  #
  # Commands:
  # p, pick <commit> = use commit
...
```
- Replace the pick command by the squash command at the editor but for the first line that should contain the summary of the commits
```
  pick 5ab8044 helms/altBranch empty certificates added
  squash 7488c0f step01 of altBranch deployment
  squash a0175d9 step02: Deploy a functional version of altBranch
  squash f405746 Step03: Deploy a new route via the altBranch.yaml file
  squash 6fb28f6 Use Admin API to manage routes
```
- Save the file and exit. A second editor will appear with the suggested changes. Remove or comment all the commit messages except the one you want to leave (In our case, the 5th one)
In the example, the only line not commented out has been _"altBranch deployed to using Admin API to manage routes"_

- After saving and exiting, the changes are performed. To review the commits now, re-run the command:
```shell
git log --oneline
9bca0cd (HEAD -> altBranch) altBranch deployed to using Admin API to manage routes
3a42eb4 (origin/main, origin/HEAD, main) Initial commit
```
- Suggestion: a good option is to [rebase your altBranch into another branch](#github-merge-using-git-rebase)

## Github: Merge using git rebase
Taken from [The Modern Coder-Git rebase](https://www.youtube.com/watch?v=f1wnYdLEpgI)
He defends the point that rebase is for complex git cleaner that merging.  
It is dangerous when multiple people is commiting to the master branch.   
NOTE: Here _master_ is just to ilustrate the example. I used _altBranch_ as the branch to rebase into _master_
```shell
# The scenario is that at this point you are at your altBranch with a number of commits.
# Downloads latest change from master
git checkout master
git pull
git checkout altBranch
git rebase master
# Solve any potential conflict and commit it.
git checkout master
git rebase altBranch
# No conflicts should appear
git push
# If an error appears, you can try
git push --force
git push --force-with-lease
```

## Github: Upgrade tag to a later commit
```shell
# Taken from https://stackoverflow.com/questions/8044583/how-can-i-move-a-tag-on-a-git-branch-to-a-different-commit

# Take the list of remote tags
git ls-remote --tags
# Delete the desired tag on any remote before you push
git push origin :refs/tags/<tagname>

# Delete local tag (if it exists)
git tag -d <tagname>

# Replace the tag to reference the most recent commit
git tag -fa <tagname>
# or
git tag -f <tagname> -m <tagComment>

# Push the tag to the remote origin
git push origin --tags
# Maybe it is required to specify the --force parameter
git push origin --force <tagname>
```