
# Finder Nvim Extension


## Adding to nvim config 
```
require("vim-options")
require("config.lazy")
local debug = require("plugins.custom.finder.lib.finder_debug")

local finder_config = {
    debug_level = debug.DEBUG_LEVELS.INFO,
    width_percentage = 0.25
}
require("plugins.custom.finder").setup(finder_config)
```

