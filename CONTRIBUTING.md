# Contributing to Cosmic Crash
If you would like to contribute to the project, please contact me on
Discord: `Shambles#3117`. You can also join the [Sphere Matchers](https://discord.gg/gJgy5x5)
Discord server, verify yourself, and find the "Cosmic Crash" thread.

## Cloning
If you are new to Git, or are uncomfortable with command-line,
it is recommended to download [GitHub Desktop](https://desktop.github.com/).

1. Fork the repository.
2. Clone your fork.
2. Start testing, or editing code/assets.

## Code
Since CC will be implementing features from Zuma Blitz that OpenSMCE does not
have, you may want to edit the codebase in order for things to, well... work!

As this project is based on OpenSMCE, please look at [OpenSMCE's contribution
guidelines](https://github.com/jakubg1/OpenSMCE/blob/master/CONTRIBUTING.md).

Keep in mind that you should mark any code that is only useful for Cosmic Crash,
like so:
```lua
-- FORK-SPECIFIC CODE: My code that only makes sense on this fork.
_Game:getCurrentProfile():getPowerLevel("sands_of_time")
```

## Gameplay Mechanics
These have been researched mostly on [Brendan Chan's Zuma Blitz blog](http://bchantech.dreamcrafter.com/zumablitz/)
and [PopCap's ZB Customer Support page](https://web.archive.org/web/20130130103017/http://support.popcap.com/facebook/zuma-blitz).

We will be altering some of them for more fun!
Keep in mind this is only a spiritual successor - minor changes are allowed.