if not pcall(require, 'fzf') then return end

local core = require('fzf-lua.core')
local helpers = require("fzf.helpers")
local config = require "fzf-lua.config"
local actions = require "fzf-lua.actions"

local M = {}

local function get_async_tasks(task_file)
  local tasks = {}
  local row = 0
  for line in io.lines(task_file) do
    row = row + 1
    local name = line:match('^%[([%w-_]+)%]')
    if name then table.insert(tasks, {lnum = row, name = name}) end
  end
  return tasks
end

local function file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

M.async_task = function()
  coroutine.wrap(function()
    local task_file = vim.call('asyncrun#get_root', '%') .. '/.tasks'

    if not file_exists(task_file) then
      print("not found tasks in this project")
      return
    end

    local tasks = get_async_tasks(task_file)

    local items = {}
    for _, task in pairs(tasks) do
      setmetatable(task, {__tostring = function(table) return table.name end})

      table.insert(items, task)
      items[tostring(task)] = task
    end

    local act = helpers.choices_to_shell_cmd_previewer(function(selected)
      return string.format(
                 'bat --style=numbers,changes --color always -l ini -H %d %s',
                 items[selected[1]].lnum, task_file)

    end)

    local opts = config.normalize_opts({}, config.globals.files)
    opts.prompt = 'Taskes❯ '
    opts.preview = act
    opts.actions = {}
    opts.actions['default'] = function(selected)
      if selected[1] == "" then
        vim.cmd(string.format('AsyncTask %s', selected[2]))
      else
        vim.cmd(string.format('AsyncTask %s', selected[1]))
      end
    end
    opts.actions['ctrl-e'] = function(selected)
      vim.cmd(string.format('tabnew %s', task_file))
    end

    if not opts.preview then
      local preview_opts = config.globals.previewers[opts.previewer]
      if preview_opts then
        local preview = preview_opts._new()(preview_opts, opts)
        opts.preview = preview:cmdline(act)
      end
    end

    local selected = core.fzf(opts, items, core.build_fzf_cli(opts), config.globals.winopts)

    actions.act(opts.actions, selected)

  end)()
end

return M
