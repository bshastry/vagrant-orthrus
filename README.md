### Overview

This is a vagrant box to test Orthrus.

### Setup

[Vagrant][1] is a headless virtualbox driver. Install it first, and then do:

```bash
$ git clone https://github.com/bshastry/vagrant-orthrus.git
$ cd vagrant-orthrus
$ vagrant up && vagrant ssh
$ tmux
$ fetch
```

If something doesn't work as expected, please ping me/file issues. This was hacked together one Friday afternoon, so flakiness expected ;-)

[1]: https://www.vagrantup.com/
