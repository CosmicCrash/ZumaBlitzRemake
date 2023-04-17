<p align="center"><img src="https://raw.githubusercontent.com/ZumaBlitzRemake/ZumaBlitzRemake/master/games/ZumaBlitzRemake/images/splash/logo.png"></p>


[![Discord](https://img.shields.io/discord/315202394118029314?color=%235865F2&label=Discord%20&logo=discord&style=flat-square)](https://discord.gg/gJgy5x5)

A preservation & recreation project for **Zuma Blitz Kroakatoa Island** using [OpenSMCE](https://github.com/jakubg1/OpenSMCE).

## About

**Zuma Blitz** was a Facebook game that used Adobe Flash, from 2010-2017. It
released on December 14, 2010. It then had a revamp in 2012, called
*Kroakatoa Island*, and was closed March 31, 2017.

This project is a collaborative effort in order for past Zuma Blitz players
to relive their 1-minute ball shooting memories.

## Running from source

Make sure [LÖVE2D 11.3](https://github.com/love2d/love/releases/tag/11.3) or later is installed on your machine.

### Windows
Run `start.bat`.

### macOS
Do the following in a terminal:
```sh
cd ZumaBlitzRemake
chmod +x ./start-macos.command
After that, you can double-click on `start-macos.command`.
```
### Linux
Navigate to the main folder in a terminal and type in:
```
love .
```

## Building

### Windows
You will need to install the following:
- [LÖVE2D 11.3](https://github.com/love2d/love/releases/tag/11.3) (32-bit or 64-bit doesn't matter)
- [7-zip](https://www.7-zip.org/download.html) and it's directory added in `%PATH%`
- [Resource Hacker](http://www.angusj.com/resourcehacker/) (optional)

Then, simply run `build.bat`. You will see a new folder named `build` after
it's finished. To skip creation of `*.zip` files, pass `--no-packages`.

### macOS
I unfortunately don't have a Mac, so someone else has to build these.

Follow [the instructions on the LÖVE2D wiki.](https://love2d.org/wiki/Game_Distribution#Creating_a_macOS_Application)

### Linux
As OpenSMCE uses LÖVE2D 11.3 due to 11.4's stability issues, AppImages
aren't an option. The only option for now is to run from source or
distributing a `.love` file.

## Contributing
See [CONTRIBUTING.md](/CONTRIBUTING.md).

Any new features added in this fork may be added to OpenSMCE in general.
