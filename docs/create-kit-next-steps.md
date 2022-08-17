# Shellkit Next Steps:
##  Creating a new kit

After you have run `make create-kit` for your new shellkit-based project, you can
define its shell helper definitions and PATH-runnable commands:

- `bin/[Kitname].bashrc`:

   This file gets installed in the user's ~/.local/bin/<Kitname> folder, and is
   hooked into `~/.bashrc` by the installer.  So anything you place into this
   file will be parsed by the shell when initializing an interactive session.

   It's a good place for aliases, small functions, environment definitions, etc.

   Usually it's not a good place for large/complex functions, which should be
   placed into their own script(s) or external tools.  *(Those scripts can
   themselves be symlinked onto the PATH, see below)*

- `bin/<_symlinks_>`:

   This file contains the names of scripts or programs which you want to be available to the user on their PATH.  All links are interpreted as
   being relative to **~/.local/bin/&lt;kitname&gt;/**, which is where
   the installer puts your kit's files.

   For example, if you have a script at [root]/bin/goobar/foo.sh in your
   source tree, you can put it into the user's PATH by adding this to
   `_symlinks_`:

   ```
   # _symlinks_ is where you declare tools which should be on the PATH
   goobar/foo.sh
   ```


