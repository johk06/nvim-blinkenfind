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

    secondary_highlights = {
        "BlinkenFind1Secondary",
        "BlinkenFind2Secondary",
        "BlinkenFind3Secondary",
        "BlinkenFind4Secondary",
        "BlinkenFind5Secondary",
        "BlinkenFind6Secondary",
        "BlinkenFind7Secondary",
        "BlinkenFind8Secondary",
        "BlinkenFind9Secondary",
    },

    highlight_non_important = true,
    create_mappings = true,
    treesitter_repeat = true,
}


local namespace = api.nvim_create_namespace("nvim-blinkenfind")

---@param line string
---@param backward boolean
---@param cursor integer
---@return ([integer, integer, string])[]
local parse_line = function(line, backward, cursor)
    local text, offset
    if backward then
        offset = 0
        text = line:sub(1, cursor)
    else
        offset = #line:sub(1, cursor + 1)
        text = line:sub(cursor + 2)
    end
    local positions = vim.str_utf_pos(text)
    if backward then
        local newchars = {}
        for i = #positions, 1, -1 do
            newchars[#newchars + 1] = positions[i]
        end
        positions = newchars
    end

    local characters = vim.tbl_map(function(b)
        local stop = vim.str_utf_end(text, b)
        local char = text:sub(b, b + stop)
        return { b + offset, stop + b + offset, char }
    end, positions)

    return characters
end

local is_ascii_symbol = function(c)
    if c == "" then return false end
    local b = string.byte(c)
    return
        (b >= 0x21 and b <= 0x2F)    -- !"#$%&'()*+,-./
        or (b >= 0x3A and b <= 0x40) -- :;<=>?@
        or (b >= 0x5E and b <= 0x60) -- [\]^_`
        or (b >= 0x7B and b <= 0x7E) -- {|}~
end

local is_ascii_upper = function(c)
    if c == "" then return false end
    local b = string.byte(c)
    return (b >= 0x41 and b <= 0x5a)
end

local is_ascii_number = function(c)
    if c == "" then return false end
    local b = string.byte(c)
    return (b >= 0x30 and b <= 0x39)
end

local function highlight_motion(cmd, count)
    local goes_backward = cmd == "F" or cmd == "T"
    local cursor = api.nvim_win_get_cursor(0)
    local line = api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1]
    local chars = parse_line(line, goes_backward, cursor[2])

    --[[
    Highlight the following:
        - non alphanumeric characters
        - first capital letter in a sequence
        - word boundaries
    ]]
    local color_index = 1
    local seen = {}
    local first = true
    for i, glyph in ipairs(chars) do
        local start = glyph[1]
        local stop = glyph[2]
        local char = glyph[3]
        seen[char] = (seen[char] or 0) + 1
        local prev = chars[i - 1] and chars[i - 1][3] or ""
        local next = chars[i + 1] and chars[i + 1][3] or ""

        local is_word_boundary =
            (next == " " or prev == " ")
            or (next == "" or prev == "")
            or (is_ascii_symbol(next) or is_ascii_symbol(prev))
        local is_camel_boundary = is_ascii_upper(char) and not (is_ascii_upper(next) and is_ascii_upper(prev))
        local is_symbol = is_ascii_symbol(char)
        local is_number_boundary = is_ascii_number(char) and not (is_ascii_number(next) and is_ascii_number(prev))

        if first then
            first = false
        elseif seen[char] == count and char ~= " " then
            local hl_group
            if
                is_symbol
                or is_camel_boundary
                or is_number_boundary
                or is_word_boundary then
                hl_group = config.highlights[(color_index % #config.highlights) + 1]
            elseif config.highlight_non_important then
                hl_group = config.secondary_highlights[(color_index % #config.highlights) + 1]
            end

            api.nvim_buf_set_extmark(0, namespace, cursor[1] - 1, start - 1, {
                hl_group = hl_group,
                end_col = stop,
                end_line = cursor[1] - 1,
            })
            color_index = color_index + 1
        end
        --
        -- local is_ascii = is_ascii_letter(char)
        --
        --
    end
end

local CTRL_A = vim.keycode "<C-a>"
local CTRL_X = vim.keycode "<C-x>"
local CTRL_T = vim.keycode "<C-t>"
local CTRL_D = vim.keycode "<C-d>"
local CTRL_O = vim.keycode "<C-o>"

local modify_find = function(cmd, count)
    local keys
    local flags = ""
    local mode = api.nvim_get_mode().mode
    if mode == "no" then
        keys = ("\x1b%s%d%s"):format(vim.v.operator, count, cmd)
    elseif mode == "niI" then
        keys = ("\x1b\x1b%s%d%s"):format(CTRL_O, count, cmd)
        flags = "L"
    else
        keys = ("\x1b%d%s"):format(count, cmd)
    end
    api.nvim_feedkeys(keys, flags)
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
