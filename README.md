# macOS

##### About
Running the make file will generate a PKG based on the root/scripts structure
and inject this into an AutoDMG template.

Runnig the make.sh will generate an AutoDMG
image (based on the currently running OS). The dmg is then used to create
a VMWare guest for testing. The make.sh script and the root/scripts structure
should be altered to suite your needs.

##### Requirements
* An OS installer in your Applications folder [ Install macOS Sierra.app, Install OS X El Capitan.app, Install OS X Yosemite.app, Install OS X Mavericks.app]
* [AutoDMG](https://github.com/MagerValp/AutoDMG/releases)
* [Xcode cli tools](https://developer.apple.com/download)
* [vfuse](https://github.com/chilcote/vfuse)
* VMWare Fusion (8 or higher)

```bash
git clone https://github.com/cgerke/macos;
cd macos;
make
```

##### Repo
- root - pkg payload
- scripts - pkg scripts
- make.sh - make script to autodmg and vfuse
- Makefile - builds a pkg and bootstraps autodmg via the cli with vfuse.
