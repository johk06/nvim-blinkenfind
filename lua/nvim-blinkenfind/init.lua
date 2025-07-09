local M = {}
local api = vim.api

local config = {
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

    highlight_non_important = true,
    non_important_suffix = "Secondary",
    create_mappings = true,
    treesitter_repeat = true,
}


local namespace = api.nvim_create_namespace("nvim-blinkenfind")

local is_ascii_letter = function(c)
    local b = string.byte(c)
    return (b >= 0x41 and b <= 0x5a) or (b >= 0x61 and b <= 0x7a)
end

local is_ascii_upper = function(c)
    local b = string.byte(c)
    return (b >= 0x41 and b <= 0x5a)
end

local function highlight_motion(cmd, count)
    local goes_backward = cmd == "F" or cmd == "T"
    local cursor = api.nvim_win_get_cursor(0)
    local line = api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1]


    local seen = {}
    --[[
    Highlight the following:
        - non alphanumeric characters
        - first capital letter in a sequence
        - word boundaries
    ]]
    local start = cursor[2] + (goes_backward and 0 or 2)
    local index = 0
    for i = start, (goes_backward and 1 or #line), (goes_backward and -1 or 1) do
        local char = line:sub(i, i)
        local next = line:sub(i + 1, i + 1)
        local prev = line:sub(i - 1, i - 1)

        next = (not next or next == "") and " " or next
        prev = (not prev or prev == "") and " " or prev

        local is_ascii = is_ascii_letter(char)

        seen[char] = (seen[char] or 0) + 1

        if i ~= start and seen[char] == count then
            local hl_group
            if not is_ascii or (
                    (is_ascii_upper(char) and not (is_ascii_upper(next) and is_ascii_upper(prev))) or
                    (is_ascii and not (is_ascii_letter(next) and is_ascii_letter(prev)))
                ) then
                hl_group = config.highlights[(index % #config.highlights) + 1]
            elseif config.highlight_non_important then
                hl_group = config.highlights[(index % #config.highlights) + 1] .. config.non_important_suffix
            end

            api.nvim_buf_set_extmark(0, namespace, cursor[1] - 1, i - 1, {
                hl_group = hl_group,
                end_col = i,
                end_line = cursor[1] - 1,
            })
            index = index + 1
        end
    end
end

local CTRL_A = vim.keycode "<C-a>"
local CTRL_X = vim.keycode "<C-x>"
local CTRL_T = vim.keycode "<C-t>"
local CTRL_D = vim.keycode "<C-d>"

local modify_find = function(cmd, count)
    local keys
    if api.nvim_get_mode().mode == "no" then
        keys = ("\x1b%s%d%s"):format(vim.v.operator, count, cmd)
    else
        keys = ("\x1b%d%s"):format(count, cmd)
    end
    api.nvim_feedkeys(keys, "")
end

local highlighted_find = function(cmd)
    local count = vim.v.count1
    highlight_motion(cmd, count)
    api.nvim__redraw { win = 0, range = { 0, -1 } }

    if config.treesitter_repeat then
        -- make ; and , work with this
        require("nvim-treesitter-textobjects.repeatable_move").last_move = {
            additional_args = {},
            func = cmd,
            opts = { forward = cmd == "f" or cmd == "t" }
        }
    end

    local had_first = false
    vim.on_key(function(key)
        if not had_first then
            had_first = true
            return
        end

        api.nvim_buf_clear_namespace(0, namespace, 0, -1)
        vim.on_key(nil, namespace)

        if key == CTRL_A or key == CTRL_X then
            modify_find(cmd, math.max(1, count + (key == CTRL_A and 1 or -1)))
            return ""
        elseif key == CTRL_T then
            modify_find(cmd == "f" and "t" or (cmd == "F" and "T" or (cmd == "T" and "F" or "f")), count)
            return ""
        elseif key == CTRL_D then
            local new_cmd = cmd:lower() == cmd and cmd:upper() or cmd:lower()
            modify_find(new_cmd, count)
            return ""
        end
    end, namespace)

    return cmd
end

M.highlighted_find = highlighted_find

M.setup = function(opts)
    config = vim.tbl_extend("force", config, opts)
    if config.create_mappings then
        for _, cmd in ipairs { "f", "F", "t", "T" } do
            vim.keymap.set({ "x", "n", "o" }, cmd, function()
                return highlighted_find(cmd)
            end, { expr = true })
        end
    end
end

return M
