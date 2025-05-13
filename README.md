# nvim-blinkenfind

Navigate faster with `f`, `F`, `t` and `T`.
- Highlight useful targets
- Allow increasing/decreasing v:count using `<C-a>` and `<C-x>` while finding.

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

### Usage

Just use the mapped commands normally.
