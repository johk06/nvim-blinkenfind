# nvim-blinkenfind

Nice colors to help you see what to `f`, `t`, `F` or `T`.

### Installation

With lazy
```lua
return {
    "dmxk062/nvim-blinkenfind",
    opts = {}
}
```

### Configuration

The following are the default options
```lua
{
    -- highlight groups to use
    -- specify as many as possible for the rainbow
    -- NOTE: these do not have a default value, either set them or use other groups
    highlights = {
        "BlinkenFind1",
        "BlinkenFind2",
        "BlinkenFind3",
        "BlinkenFind4",
        "BlinkenFind5",
        "BlinkenFind6",
        "BlinkenFind7",
        "BlinkenFind8",
        "BlinkenFind9",
    },

    -- map f, F, t and T
    create_mappings = true,

    -- integrate with nvim-treeesitter-texobjects to allow for ; and , to work the same
    treesitter_repeat = true,
}
```

#### Using another set of mappings
```lua
local blinkenfind = require("nvim-blinkenfind")
blinkenfind.setup {
    create_mappings = false
}

vim.keymap.set("<leader>f", function() blinkenfind.highlighted_find("f") end)
```
