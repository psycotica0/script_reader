The first thing I need to justify is the length of this video. You can find other videos out there that will purport to teach you git in only a few minutes. But wait, don't leave yet! Here's the thing, this videos are often just a loose _soup_ of commands, presented like they're magic spells. And if you just memorize these mysterious incantations, and reproduce them *exactly*, in exactly this order, every time, then you too can use the inscrutable tool that is git! But if you ever make a mistake, or if you ever want to do anything besides these presented tasks, then the evil and capricious git will give you strange unknowable errors, or maybe even eat all your data entirely!

But... no. Git is actually very logical and predictable. The problem is that these videos are trying to teach you how to accomplish tasks, which makes sense because tasks are exactly the things you're _trying_ to accomplish, but as a result you end up with tonnes of people who use git for 10 years and still have no idea what the commands they have to run are *for*. And when anything goes wrong, they're just lost. So instead, what I'm going to teach is the _intuition_ behind git; The simple ideas that underlie the whole thing. It takes a little more time, but honestly not that much more in the grand scheme of things. And when I'm done, learning the actual _usage_ of git will come naturally. It'll just be a case of giving names to the concepts that already make sense to your brain. Trust me.

Just to make sure we're all on the same page here: Git is a Version Control System. This means its job is to track different versions of some set of files across time. This allows you to revert a file back to a previous checkpoint, or to see what changed between versions, which allows you to make changes confidently knowing that nothing will be truly lost. And that history and those files belong to what git calls a "repository", or "repo" for short. In practice, a repo is just the folder or directory that contains the files you're interested in, and different independent projects will have usually have different independent repos, which means different histories. And since it's good at tracking different versions of files, it's also good for collaboration between multiple people. I may have a version on my computer that I'm working on, and you have a version you're working on, and git can help manage that situation.

We'll get to that later, though. For now let's focus on just your own computer. Let's try to imagine the simplest solution to this problem of storing multiple versions. In fact, it's probably something you've already done before! We could take our file, call it "File.txt", and make a copy called "File.txt.001". Poof, just like that we have a version saved, and we can keep working on "File.txt" knowing we won't lose what's in "File.txt.001"! And when we're happy with where we're at, we can make another copy called "File.txt.002", and now we have two copies, on top of our working copy! The "Working Copy" is what we'll call the "real" version that we're working on. It's the one that would exist even if we weren't doing anything fancy, in this case just "File.txt". This solves our immediate problem, but creates some new problems. The first problem is that our folder will get pretty cluttered, and we don't really need these other copies 99% of the time. They're there in case of trouble, but otherwise they're just in the way.

To solve this we can make a hidden folder in our repository. Remember, repository is just the fancy name we're giving to the folder our files live in. So we make this hidden folder, and then we can build a tool that, given a file we want to save, just makes a copy of it and puts it in the hidden folder. Now we can know our file contents are safe, but we don't actually have to _see_ these copies. And then our tool could also retrieve a particular version out of the hidden folder when we need it. Now, this is pretty simple, but we've already unlocked some pretty great abilities. Specifically we can save copies, and edit our working copies without worrying about losing anything. And we can compare our latest saved copy with our working copy to see what changes we've made since we last checked something in. Essentially, what's new, and therefore what's at risk of being lost if we don't make a new check-in. But! We can also compare any two _previous_ versions of our file as well, to see what changed between *them*, to get a sense of _when_ something changed. If these files are text files, we can compare the two files line by line in what's called a "diff" between the files, finding everywhere a line was added or removed. "Diff" obviously short for "difference". If the files _aren't_ text files, like if they're image files or something, you could at least look at the two versions side-by-side to see the differences for yourself. And the last thing you can do already, is to revert a file to a previous version. It's as easy as deleting the working copy, and copying one of your previous copies into the main folder, to be the new working copy.

Once our tool is making copies, though, we have to decide what to call them. The obvious way is the "File.txt.001" names we previously talked about, but there's a few issues with that. The first is that there's an implied order there, which is good when it's right, but bad when it's wrong. Like, let's say we had "File.txt.001, 2, 3, 4, 5". Now maybe we decide we actually don't like the way we've been going with this, and want to try something else. Well, we can switch back to "File.txt.003", that's the whole point of using a Version Control System after all, and we make some changes in a different direction. When we go to check this file in, it will call it "File.txt.006", which _feels_ like it'd come after "File.txt.005", but it actually doesn't. It comes after "003", and "004" and "005" are actually unrelated to "006". The problem gets even worse when collaborating with others, though. If we've both got copy 005, and then I make changes I'll get 006. But when you make different changes, you'll _also_ get version 006, but it'll be *different*! That's going to cause trouble when we're trying to work together. What we really want is a name that's unique in some way.

This is git's first trick. There's a math operation called a "hashing function", or just "hash", which computes a kind of "fingerprint" of some data. The idea is that a particular file contents might give one value, but if it's even _slightly_ different, it'll produce a completely different fingerprint. But all fingerprints are always the same length, which is almost always smaller than the data we're interested in. If you've ever seen an "md5" or "sha1" file when downloading something off the internet, it's the same idea. We can check that the data we downloaded is correct by computing the hash of what we got, and then comparing against the fingerprint we're expecting. But in this case, that's not what we need it for. In this case we can use it to make a unique name for our copy, based only on its contents! So if you and I have the same version, it'll have the same name on both of our computers. And as an added bonus, if we ever have a file stored, and then we add a few lines to it, and then later decide we don't need those lines after all and take them back out, we'll go to compute the hash and get the same value as before. And then git will know it doesn't need to store this again, it already _has_ this version! Great!

Alright, that solves one of our problems. We could use this, as is, and it would work okay. But we can do better. You see, the issue with this is we've solved the problem for individual files, but usually the version of one file is related to the version of another file. Maybe we added some code in one file, and we're using it in another. Or maybe we're referencing some images or text from another file in this file, and we expect them to go together. If we mix up this version of this file with that version of that file, it could be a disaster... or at the very least confusing. So, if we want to associate versions of different files together... the simplest thing we could do is something like this:

```
d144d4811cdfb7f3a929dfebd1de8e1d9a4ed312  Die.gd
48e373f9ca06aec8d26c705d4400715b97d16744  Die.tscn
f4163f3ed4122b4c994e44201c9a1c025b236b0a  DieControl.gd
```

Here we've just listed each filename along with the hash of this particular version of the file in our hidden folder. With this we now know all the versions of our all files that co-existed at one point in time. Rather than a snapshot of a single file, it's a snapshot of all the files in the folder. But if we wanted to keep this around, we'd have to store it somewhere... Here's git's second big trick. This file listing is just content, and we already have a system that can turn content into a unique filename, and a place we store things that only git can see! So we can just hash it, and store it at that name like it was a normal file! And what's even better, by hashing it it means the snapshot of this whole file listing ends up with one single hash we can use to reference the versions of *all* of these files. And there's no need to keep track of which versions of file A go with which version of file B.

What about sub-directories. Well, we _could_ do it like this:

```
d144d4811cdfb7f3a929dfebd1de8e1d9a4ed312  Die.gd
48e373f9ca06aec8d26c705d4400715b97d16744  Die.tscn
f4163f3ed4122b4c994e44201c9a1c025b236b0a  DieControl.gd
24f867f75c1a291348ba20c47da4fa9b3c226da7  Enemies/Bullet.gd
```

where we just list the names with slashes right in the listing. And that would work. But we can do better. Because our file listings get a name in our system too, we can store the listing for the sub-folders first, and then in the main folder, we can just point to that listing, the same way we point to the other files!

```
d144d4811cdfb7f3a929dfebd1de8e1d9a4ed312    Die.gd
48e373f9ca06aec8d26c705d4400715b97d16744    Die.tscn
f4163f3ed4122b4c994e44201c9a1c025b236b0a    DieControl.gd
387257aebd8126dc5f0c5aa7b5ef997254ea2eab    DieControl.tscn
b00aaa97dc2772d980334acd67ebf5d7f95b434c    Enemies
90284e59434b06b53b7338c53e45237f7bfc144d    Exports
```

Of course, now that we're storing two different kinds of things is the same place... we can't really call that place "the place copies get stored" anymore, because there's other stuff there. Git picks a pretty abstract name and calls all of these things "objects", and thus the place we store these things is "the object store". Pretty exciting stuff. The things we've been calling "copies" up until now, git calls "blob objects", because git doesn't know what they are. It doesn't read them, it doesn't interpret them, they're just some blob of data. Blob objects. And then the file listings are call "tree" objects. Tree, because by linking to other sub-folders as sub-trees, it forms a kind of tree structure.

Now we can mark in our tree objects what kind of object each row represents, so we know if these are files or other folders.

```
blob d144d4811cdfb7f3a929dfebd1de8e1d9a4ed312    Die.gd
blob 48e373f9ca06aec8d26c705d4400715b97d16744    Die.tscn
blob f4163f3ed4122b4c994e44201c9a1c025b236b0a    DieControl.gd
blob 387257aebd8126dc5f0c5aa7b5ef997254ea2eab    DieControl.tscn
tree b00aaa97dc2772d980334acd67ebf5d7f95b434c    Enemies
tree 90284e59434b06b53b7338c53e45237f7bfc144d    Exports
```

You may be wondering why this version is better than the one where we just list all the files in one listing. The main advantage here is that if we have some folder with a lot of files in it that don't change very often, we get to only store that list once, and just reference it in multiple versions from then on; we don't have to re-list these items over and over.

Also, we can calculate the diff between two trees if we want to see what's changed between two snapshots, by comparing the versions of the same file between the two listings. If two blobs have the same hash, then we don't have to look for differences between them. They're the same! If the blobs have different hashes, then we can look for differences line-by-line like before. But we can do the same thing with trees! If two tree items have the same hash, then we don't have to look for any differences there. Because all of the individual blob and subtree versions are included in this version, if any of them changed, then we'd end up with an entirely different tree address. So the only way to have the same tree address, is if all blobs in this sub-tree, and any blobs in those subtrees, are all identical and unchanged. No matter how many files are in those subfolders, we can tell right away that there's no differences in there, which can be a big help.



--

Okay, so, you mentioned making copies of files to save their state. In a sense that's what git does, but in a way that's more complicated to support more features. I should also mention here that git is not the first or only version control system. They've been around in some form or another since at least the 80s, but git quickly became the most popular after its release. Unlike some of the earlier ones, git is what's called a "distributed version control system", meaning any copy of the "respository" (the folder where files are stored) is as good as any other. Older ones were "centralized", meaning that there was one main central repo (short for repository) which had all the versions and history and stuff, and all the people would basically just be working on a single snapshot of that repo, and then contributing changes back to it. But that central repo had to be created, and if it ever went down everyone was screwed. With git, though, everything works locally, basically, and the syncronization is just an optional step you could do if you wanted to.

The other thing to mention is that "git" and "GitHub" are fully different things. A lot of people only encounter git through GitHub, so it's an understandable and common mistake to assume they're the same, but they're actually only somewhat related. Git was first released in 2005, and GitHub in 2008 by different people. GitHub is obviously based _around_ git, and provides services to git users, but the authors and maintainers of git aren't employed by GitHub and never have been. There are alternatives to GitHub, such as GitLab, Codeberg, SourceHut, which work in basically the same way, while all using git under the hood.

Okay! History lesson over! Let's talk about git! So, lets imagine we have a file we want to save. The simplest way to do it would be to make a copy. But if we didn't want our folder to be full of "File.gd.1", "File.gd.2", "File.gd.working", "File.gd.kinda broken", we'll need to put them somewhere else. So we could make a hidden folder and put the copies there! Then we could build a tool that copies our files into the hidden folder for us, and pulls them out when we want to revert to an older copy. Great! And once we're storing all these copies, that also unlocks the ability to do things like compare to versions line-by-line to see where they differ, or also to compare the current real version in what we'd call the Working Directory (or Working Folder) to the most recently stored version to see what's changed since we last made a checkpoint. Great!

But we'd have to have to figure out what to name these copies... We could just have a number, like `File.gd.008` and `File.gd.012`, but that kinda sucks as soon as we want to collaborate with other people. If I check-in a new version of `File.gd` on my computer, I'll get `File.gd.013`. But if you do the same, you'll _also_ get `File.gd.013`, but they'll be different! Not awesome. What if instead we made up a unique name based on the _contents_ of the file. I don't know if you've encountered `*.md5` or `*.sha1` files, but it's the same idea. We do some big complicated math formula on the entire contents of the file, in order to get a single big "number" that represents the kind of "fingerprint" of the file, and if the file is even slightly different it'll produce a completely different fingerprint. By the way, we call this a "hash" function.

So anyway, now when you want to check-in a file, the tool can hash it to get a unique name, and use that to store the copy! Now if you and I are both working on this thing, we can be sure that our copies are always unique. As an added bonus here, it also de-duplicates for free, since if we happen to make some changes that result in the file having the same contents it used to, like if we added some lines and then deleted them back out again, it will hash to the same value and git can say "Oh good, I've already got this one, I don't need to store it again".

Perfect! And for reasons that will make sense later, let's call the hidden place these copies are stored "The Object Store", or just "the store".

If we did that, this would work fine. But we can do better. Because one problem we have here is that it's only per-file. But often I want the changes from multiple files to be kept together, as a set. Like, if I add a method in `Player.gd`, and then make use of that new method in `Enemy.gd`, then I want these two versions to be linked. I wouldn't want to revert only one of them while leaving the other, because that would be broken and wouldn't run.

So... here's git's first big-brain move. I could make a list of all the files, along with their current versions. Something like:

```
d144d4811cdfb7f3a929dfebd1de8e1d9a4ed312  Die.gd
48e373f9ca06aec8d26c705d4400715b97d16744  Die.tscn
f4163f3ed4122b4c994e44201c9a1c025b236b0a  DieControl.gd
```

that way we'd have a snapshot not just of one file, but of the entire _set_ of files, all at the versions that existed together! But we'd have to store this somewhere... Well, it's a file, with contents, so we could just compute the hash of _this_ file, and jam it into the Object Store alongside all the copies! That would give me _one_ hash, like `da04907ee9b2fdc471fba1f24a5d5fcea95d3a09` which would point to the entire _list_ of files, which would contain all the other versions, along with what that file was called at the time (which is something we lost when we stored files as their hash). So now we've got two different kinds of things in the object store, so it may be a good idea to give them types. We call the file contents "blobs", because we don't know what's in them, they're just some data. And we call these directory listings "tree" objects.

Why "tree" objects? Well, because of how we handle sub-directories. We could store them like:

```
d144d4811cdfb7f3a929dfebd1de8e1d9a4ed312  Die.gd
48e373f9ca06aec8d26c705d4400715b97d16744  Die.tscn
f4163f3ed4122b4c994e44201c9a1c025b236b0a  DieControl.gd
24f867f75c1a291348ba20c47da4fa9b3c226da7  Enemies/Bullet.gd
```

and that would work fine. But often in situations like this there are entire sub-directories that might be big (like storing textures or whatever), and don't change very often. In that case, we could store each folders' contents separately, giving it its own name, and then we just link to that in our parent folder! Kinda like how our object pointed to our dictionary earlier. So, we'd have to change our listing now to specify what kind of item we're listing, but now it could look like:

```
100644 blob d144d4811cdfb7f3a929dfebd1de8e1d9a4ed312    Die.gd
100644 blob 48e373f9ca06aec8d26c705d4400715b97d16744    Die.tscn
100644 blob f4163f3ed4122b4c994e44201c9a1c025b236b0a    DieControl.gd
100644 blob 387257aebd8126dc5f0c5aa7b5ef997254ea2eab    DieControl.tscn
040000 tree b00aaa97dc2772d980334acd67ebf5d7f95b434c    Enemies
040000 tree 90284e59434b06b53b7338c53e45237f7bfc144d    Exports
```

Where we see that `Die.gd` is a file, whereas `Enemies` is a folder (tree object), and if we follow `b00aaa97dc2772d980334acd67ebf5d7f95b434c` we see that it itself contains 

```
100644 blob 24f867f75c1a291348ba20c47da4fa9b3c226da7    Bullet.gd
100644 blob 4499b2962d68bc9d428e3db99b9dd3acbfe7002d    Bullet.tscn
100644 blob ef11724dff84393380083cac44a5fe427a4db63e    Flak.gd
100644 blob 185ebb7384b8b8b794de1dee83f385a18ba5a35f    Flak.tscn
```

and may even contain sub-trees of its own. So that's why it's a "tree" type, because it can branch out from the root folder. And if none of my enemy code changed in a particular version, all of the files will have the same hashes, so the file listing will be the same, so _it_ will have the same hash too, and we won't have to store anything new to list it in the parent folder! It'll also be obvious when computing the difference between two trees that if this entire subtree is the same, then we don't have to look for differences in there, I can tell they're the same from here!

We didn't talk about the numbers out front of the listing. That's the permissions of the files, like which ones are readable, writable, executable. It's something that's worth storing, since we've got a listing anyway, but they're not critical.

Okay! Now we're storing snapshots of our entire folder trees and every file within in an easy to retrieve way. And we can refer to a particular version with a single identifier pointing to the root tree of a particular snapshot. But in order to remember our history, and be able to compare between versions, etc, we need to keep a list of these hashes around. And we _could_ do that, that'd be fine, but we can do better. Just like our tree object, we could create an object that looks like:

```
tree 8caa60921c14a7a56040be02b1f37fbc773adc47
```

Which would just store that at this point in time, this was our root tree object. And like with the tree object before it, we could hash _this_ file and store it in our store too, which gives us an identifier for these contents in the future. But that'd be kinda dumb. We've just turned one hash into another, which isn't super useful. But here's git's third big-brain idea. Because we could remember (as in, store in a file somewhere) that our latest check-in was `05ef9b247b6e6bfca3bd25a61aaa66273a8979ab`, which has the contents listed above, just the tree identifier. And then when we go to make our _next_ check-in, we could store contents kinda like:

```
tree 78ce411563d86b68e09bde2323407bd23d4e7e31
parent 05ef9b247b6e6bfca3bd25a61aaa66273a8979ab
```

Which says that this new check-in has this as its new tree, and that the check-in _before_ this was this. Now what I've built is a _chain_ of these objects, and all I have to remember is the hash of this newest one, and I can follow the parent-relationship backward to get to the previous one when listing the whole history. And as we go, we keep doing this, so my parent may have a parent which has a parent which has a parent, etc, on and on until the first point in my repo's history.

We call this object type a "commit", because it's a check-in of a whole set of files at a point in time. We're "committing" this state to memory. And the name that's computed is referred to as a Commit ID, or Commit Hash, or often just Commit, because that's what we'll share around, and what will refer to a particular snapshot in history. And what's better, since we've got this commit object anyway describing a particular point in time, we can put other information here, like:

```
tree 78ce411563d86b68e09bde2323407bd23d4e7e31
parent 05ef9b247b6e6bfca3bd25a61aaa66273a8979ab
author Christopher Vollick <0@psycoti.ca> 1657926324 -0400
committer Christopher Vollick <0@psycoti.ca> 1657926324 -0400

    Bouncing and Levels

    I've decided I'm going to design levels rather than generate them.

    So I've started some of that here! We have a level, it moves up, and the
    plane bumps into the things and stops. And when it bumps into something
    going downward, the level bumps upwards so you can't get dragged off the
    bottom.

    The plane knows it hit something, the wall knows it hit the plane, I
    think we're all good here for now.

    There's a bit of a physics bug when the timescale is set pretty high
    where the plane doesn't notice being pushed when it's not trying to
    move, but that's probably ok to ignore for now.
    It's unplayably fast.
```

This gives the essential information from before, but also lists who made this commit, which is useful when collaborating. It also lists the date and time the commit was made (the stored as a Unix Timestamp, the number in the `author` field), and then a human-readable description of what this commit represents.

You can always compare one commit to another to figure out the files and lines that changed between them, but often it's useful to have a commit message with a summary title on the first line and further details, so that when looking back through history you can get a sense of what this change actually represents, without having to deduce it from the changes, which may be big.

And that allows you to list a history like:

```
* ce19524 Basic UI
* 94a5e98 Don't Remove Self
* 190b372 Enemy Planes
* c4e8c82 Mortars
* 30123c9 Flak Cannons
* 7611103 Add Basic Dice System
* 4c50201 Basic Health System and Throttle
* bd2e107 Bouncing and Levels
* 05ef9b2 Initial Commit
```

based entirely on just storing the latest commit hash!

So all of that is local to your computer. But honestly, the collaboration part of git isn't much more than just uploading all the items in the object store that the remote side doesn't have, and downloading all the ones it has that you don't. That's enough to get all the commits, all the file versions, etc. So that's the core of what GitHub is, it's a remote place you can push your git objects to and pull git objects from. And then on top of that they also have a built-in front-end that allows you to see the tree and all the file versions online without having to clone the repo locally (clone meaning to make a new empty git repo locally and then sync down all the remote objects). Then they also add things like Issues and Pull Requests (where you ask someone to merge your commits to their repo), and things like automation that builds your code every time you push a new commit and stores the result in a way people can download, etc.

Two more simple concepts you'll likely encounter are branches and tags. Since the only thing we need to know to find our entire history is the latest commit hash, and our commit chain is entirely based on each commit listing its parent, there's no reason we couldn't have _different_ commits both reference the same parent. This would make a branching-off point in the history where we went along and then some commits started making some changes, and another set of commits made an unrelated set of changes. They share a history, but are now entirely parallel. If we give each of these different "HEAD" commits different names, then we can refer to these as two indepentent branches of our commit history, and we can switch between them. When we're on branch A we'll have this history and these file contents, and when we're on branch B we'll have a different history and different file contents. By default every new git repo creates a first branch named "master" (unless you configure it to use a different name), and if you never change branches this is where all your commits will go. But when collaborating your remote repos (like on GitHub) will be represented by their own branches representing what the history on GitHub is. And then you can push or pull or merge your changes from your local branch to the remote one. Or maybe someone else made a change on their branch, but that won't affect your local branch until you specifically pull their changes in. So that's how branches are used, but it's important to remember that what the branch really is is just a name that's attached to the newest commit hash for that branch. And when a new commit is made, the current branch gets updated with the new commit, and all the other branches stay the same and keep pointing at their own commits. And a tag is basically just a branch that never moves. It's a static name that always points to the same one commit object, representing a particular snapshot in time, usually used for things like "v1.2.5" or "build-7" or whatever. It's a way of tracking which version of the code was associated with some particular release or something in a way that doesn't change, which allows you to do things like compare it against another release or whatever.

The last part of branches that you'll encounter if you collaborate is branch merging. The simplest version is the "fast forward", where my history is an ancestor of yours, so I just zip my HEAD up to match yours and I haven't lost anything and am all caught up now. This is common when following some new release of upstream changes. When our branches differ, we can instead do a "merge" merge, which is a commit that has two parents. This effectively ties the two branches together in the history, and the contents of the tree in this "merge commit" represents the merging of the contents of the two trees of the parents. If these changes are independent, like in totally different files, or sometimes even just different parts of the same file, then git can often automatically merge these trees for you. But if the changes are too close together, it may not know how to merge them and it may have "merge conflicts" where it has to ask you "Here's what the two versions look like. What should the result look like?" and you have to edit the code manually to put them together. Another thing you can do, though, is a "cherry-pick", which just takes a commit from another branch and applies it to the current branch. Essentially it computes the difference between that commit and its parent, generating what's often called a "patch", and then it tries to apply that patch to our current head. And if it works and applies automatically, then it makes a commit with the same message and author as the other one, and if it doesn't, then it has to ask you to fix it and do the merge manually. And then you can commit the result. But, this is important! This commit has the same metadata, but it's **not** the same! It points at a different tree (the merged one), which means it has different contents, which means it has a different commit hash! So it's a _copy_, and perhaps spiritual sibling, of the original, but is different, and will show up in the git history separately! And then there's a "rebase", which is a chain of cherry-picks for longer branches that basically figures out which commits are on that branch that aren't on this branch, and then cherry-picks them one after the other in their original order, essentially replaying that branch's history on this branch, pausing if it hits a conflict. Like with cherry-pick, this results in a new set of commits that are similar to, but distinct from, the ones on the other branch.

And now you know more about git than basically everyone who uses git, except I haven't told you at all how to actually use it! Lucky you! But this is my favourite way of teaching stuff. First explain the intuition, then how to use it. Many people use git via the command-line, but many others use it via a graphical client. And Godot itself has some kind of git integration I've never used, but it's built-in somewhere. These concepts, though, should be present in some way or another in all the clients. There's commits, and a history or log or tree showing their relationships, there's the "working tree/directory/folder" which is where your "real" files are, there's "diffs" which are the difference between either working tree files and your HEAD commit, or between two commits or branches or tags. And there's remotes you push and pull changes from and to, and merges and cherry-picks and rebases for integrating changes between branches and tags. Many of them will have some kind of a "stash" which temporarily hides your changes from your working dir, effectively resetting you back to HEAD. Useful for seeing if you caused some bug or if it was always there. And usually some way to go back to a previous version entirely. Then to "unstash" and get your working changes back into the working dir.

The last thing that practical git has is the "index". It's not essential to the way git works, and some other version control systems don't have an equivalent, but it enables some convenient stuff. The index is a staging area where the changes to be commit are stored. This allows you to commit only _some_ of the changes from your working dir to the store in a particular commit. Maybe there are some changes that are just for your testing, and you want to leave those out but commit the other changes. Or maybe you actually made two different independent changes since your last commit, and you want to commit these changes first, then commit those changes. If git always copied directly from the working dir directly into the store, you'd be a bit screwed here. But instead it takes changes from the working dir, stages them in the index, and then later commits what's in the index into the store. Most tools have some way to say "just commit all my changes" which effectively puts all changes into the index, and then commits that index, all at once. But they also usually have some way to "add" or "stage" changes bit by bit, block by block, and then commit only what's been staged.

Also, git will completely ignore any files you've never told it about. So if your working dir has "Player.gd" and "Enemy.gd", and you've only ever added "Player.gd", it will only track and commit and show differences for "Player.gd", and "Enemy.gd" is entirely _untracked_, which means its changes won't be secured, etc. As far as the repo is concerned that file might as well not exist, even though it's in the working dir. That's sometimes what you want, like if it's just some notes for yourself, or a debug log or something, but it's just something to be careful of. Most clients will have some kind of way to see untracked files and warn you about them, but yeah. Most tools also have some way to mark a file as _explicitly_ ignored, which means it won't warn you about it being untracked. This is often a good idea, as it keeps the "untracked" warnings topical, which means you're more likely to notice when there's something in there you actually _did_ want to commit. If it goes from 0 to 1 untracked file, you'll look at it. If it goes from 17 untracked files to 18, you probably won't notice. I know I won't. 😛

So yeah! With this knowlege, you may go forth and use whatever client strikes your fancy. Like I said, I believe there's one built into Godot itself, but I've never used it and can't vouch for its quality. If you happen to be a command-line person, which I assume you are not, I can go over the command-line interface in more detail. Other than that, there's also a GitHub desktop client and I know some people use GitKraken because they like the way it looks, etc. Lots of options from here, but they all essentially wrap around the same core concept, and in theory you could use any of them in the same repo as each other, and they'd all interoperate fine. All that really matters is what's in the store.

So yeah, sorry for the massive wall of text, and if you somehow followed this monstrosity enough to have questions, feel free to ask away!
