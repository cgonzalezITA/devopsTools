# git Tools
This folder contains scripts to ease certain operations on the git environment.
- [git Tools](#git-tools)
  - [Creating a git keypair certificate](#creating-a-git-keypair-certificate)
  - [Commit with comments](#commit-with-comments)
  - [Pushing all the gits (main git and submodules) with just one command:](#pushing-all-the-gits-main-git-and-submodules-with-just-one-command)
  - [Freeze a file](#freeze-a-file)
    - [Changing branch with skipped files involved](#changing-branch-with-skipped-files-involved)

## Creating a git keypair certificate
If opting for the **git@** ref. you will be required to have a git keypair certificate setup (the symptom is that you will be asked for the git password that does not match the user password). You will have to add hence a keypair certificate to your machine to connect to the git.  
Execute the following steps at an Ubuntu machine in which the git has to be cloned (For windows environments see the [presentation de metología del dpto ITA BDSC -git sin passwords-](https://feditmpsa.sharepoint.com/:p:/s/TD_BD_Sistemas_Cognitivos2/EUsBoj-0XsBFjQ5AVnV5UJABpygh1x9vMnwkAfGIddkt_Q?e=55cl18)):
1. (Linux & Windows) Generate the certificate
```
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
```
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
```
$ vi ~/.bashrc
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
> USAGE: gCommit.sh [-h] [-s <submodulePath>] <comment1 (with quotes ")> [<comment2 (with quotes ")>]
> 

## Pushing all the gits (main git and submodules) with just one command:  
To enable this multi-git command, git has to be connected to the git origin, not the https origin. From the tools folder execute:  
Check the remote url:  
> git remote -v  

If it is linked to the https repository, execute the following command to link to the git equivalent one (that can be found at the repository page of the git site):  
> git remote set-url origin <gitRepository origin: eg.git@github.com:cgonzalezITA/devopsTools.git>  # Customize it to your git

2- [Create a keypair certificate to connect to the GIT server](../README.md#creating-a-keypair-certificate)
Follow the steps described at [Create a keypair certificate to connect to your GIT server](../README.md#creating-a-keypair-certificate) or [view methodology guidelines](https://feditmpsa.sharepoint.com/:p:/s/TD_BD_Sistemas_Cognitivos2/EUsBoj-0XsBFjQ5AVnV5UJABpygh1x9vMnwkAfGIddkt_Q?e=M5zo7V)  

3- Add the following line to the ~/.gitconfig  
```
[alias]
    push-all = "! find . -depth -name .git -exec dirname {} \\; 2> /dev/null | sort -n -r | xargs -I{} bash -c \"cd {}; git status | grep ahead > /dev/null && { echo -e '\n********** Pushing: {} **********'; git push; }\""
```
Then just execute 
> git push-all or the script ./gTools/gpushAll.sh


## Freeze a file
The gTools/gFreeze.sh command implements this behaviour.  
See [this article from medium](https://medium.com/@adi.ashour/dont-git-angry-skip-in-worktree-e9c77dec9d15), [git assume unchanged skip worktree](https://www.baeldung.com/ops/git-assume-unchanged-skip-worktree)  

If you have a file commited at git that should not have further changes commited, it has to be 'skipped'. To mark the File as Skipped (skip-worktree) to stop tracking changes to that file while keeping it in the repository run these commands at the git folder:
```
> git update-index --skip-worktree <your-file>  
OR 
git update-index --assume-unchanged <your-file> # Not recommended

# The --skip-worktree flag is more suitable than --assume-unchanged for configuration or files that you want to keep locally modified but not include in future commits.
```
To undo the operation just run:
```
git update-index --no-skip-worktree <your-file>
OR
git update-index --no-assume-unchanged <your-file> # Not recommended
```

### Changing branch with skipped files involved
If the skipped file differs between the current branch and the target branch, an error like "Please commit your changes or stash them before you switch branches." will appear cancelling the switching of branch. To solve the issue, follow these steps:  
```
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
