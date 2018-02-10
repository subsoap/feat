# Feat
Defold achievement and stat tracking for use with DefSave and DefSteam

## Installation
You can use Feat in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:

	https://github.com/subsoap/feat/archive/master.zip

Once added, you must require the main Lua module in your scripts via

```
local feat = require("feat.feat")
```

You'll then want to add feat functions for init / update / final. See example for usage.

Feat was made to simplify the process of adding stats and achievements to your game with the ability to auto-unlock based on stat progression and auto-unlock and sync on Steam.

You will need to follow DefSteam instructions to properly include Steamworks libs in your project. This uses the testing Spacewar game for the example testing. Use Steam Achievement Manager to reset your Spacewar stats if necessary.

TODO: Add support for iOS/Android native achievements/stats.
