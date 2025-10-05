# nvim-blinkenfind

Navigate faster with `f`, `F`, `t` and `T`.
- Highlight useful targets
- Increase/Decrease v:count using `<C-a>` and `<C-x>`
- Change type of find using `<C-t>`
- Change find direction using `<C-d>`

### Installation

With lazy
```lua
return {
    "johk06/nvim-blinkenfind",
    opts = {}
}
```

## Configuration
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
    -- also highlight targets not at word boundaries etc
    highlight_non_important = true,
    -- suffix to use for those highlight groups
    non_important_suffix = "Secondary",

    -- map f, F, t and T
    create_mappings = true,

    -- integrate with nvim-treeesitter-texobjects to allow for ; and , to work the same
    treesitter_repeat = true,
}
```

### Highlight Groups
Blinkenfind will use as many highlight groups as you give it.
The default highlight groups (BlinkenFind1 .. BlinkenFind9) are *not* created by this plugin.
Some sensible highlights might be:
```lua
{
    highlights = {
        "Substitute"
    },
    secondary_highlights = {
        "Visual"
    }
}
```

If you want more colors, linking the BlinkenFind1 .. BlinkenFind9 groups to
some others might be helpful.

### Different mappings
If you want to use different keymaps to trigger highlighted find, e.g. prefix them with `<leader>`:
```lua
--[[ Config: ]] {
    create_mappings = false,
    ...
}
for _, key in ipairs {"f", "F", "t", "T"} do
    vim.keymap.set({"x", "n", "o"} "<leader>" .. key, function()
        return require("nvim-blinkenfind").highlighted_find(key)
    end, { expr = true })
end
```


## Usage

- Just use the mapped commands normally.
- Important positions will be highlighted:
    - Start/End of words
    - First capital letter after lowercase (camelCase)
    - Punctuation
    - Characters before/after punctuation
- If you made an error or cannot reach your target yet:
    - Press `<C-a>` to increase count
    - Press `<C-x>` to decrease count
    - Use `<C-t>` to cycle between `f` and `t`
    - Use `<C-d>` to change the direction
