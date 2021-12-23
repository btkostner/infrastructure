# docs/encryption

When creating this repository, I wanted to keep it public so other people can see the work. Sadly this can be a bit tricky with infrastructure, as there will inevitably be secrets you don't want to show the world. To cope with this, I am utilize `git-crypt` to conveniently encrypt and decrypt specific files. These files include the ansible group variables in `ansible/inventories/production/group_vars`, and terraform files in `terraform/`. For a complete list of encrypted files, you can view the `.gitattributes` file in the root of this repository.

## Setup

Installing `git-crypt` is painless on most modern day systems. If you are running a Debian based Linux distribution, you can simply run:

```sh
apt install git-crypt
```

If you are running macOS, you can do:

```sh
brew install git-crypt
```

For anything else, I'd recommend looking at the [git-crypt installation guide](https://github.com/AGWA/git-crypt/blob/master/INSTALL.md).

## Using

`git-crypt` is very simple to use. Once you have it installed, run this command with the base64 encoded GPG key:

```sh
echo "<base64 encoded GPG key here>" | base64 -d > ./key.gpg
```

Next up initialize `git-crypt` with:

```sh
git-crypt unlock ./key.gpg
```

And lastly, clean up the `key.gpg` file to ensure it doesn't get checked in:

```sh
rm -f ./key.gpg
```

All of the files in this repository should now be readable to you. If you make any change to one of those files, they will be re-encrypted on `git commit` and not leak any data to the public.
