### Overview

This is a vagrant box to test joern-runtime. It contains the complete joern setup + Markus' tooling. In addition it contains a couple of production codebases that are known to have vulnerabilities.
  - OpenvSwitch 2.3.2
  - libosip 4.1.0 [WIP]

### Setup

[Vagrant][1] is a headless virtualbox driver. Install it first, and then do:

```bash
$ git clone git@gitlab.sec.t-labs.tu-berlin.de:collaboration/vagrant-joern-runtime.git
$ cd vagrant-joern-runtime
$ vagrant up && vagrant ssh
$ tmux
$ fetch
```

If something doesn't work as expected, please ping me/file issues. This was hacked together one Friday afternoon, so flakiness expected ;-)

[1]: https://www.vagrantup.com/
