local actions = require 'telescope.actions'
local finders = require 'telescope.finders'
local pickers = require 'telescope.pickers'
local conf = require('telescope.config').values
local entry_display = require 'telescope.pickers.entry_display'
local action_state = require 'telescope.actions.state'
local themes = require 'telescope.themes'

local commands = {
  issue = {
    close = { 'Close the current issue' },
    reopen = { 'Reopen the current issue' },
    create = { '[repo] Creates a new issue in the current or specified repo' },
    edit = { '[repo]', 'Edit issue <number> in current or specified repo' },
    list = { '[repo] [key=value]', 'List all issues satisfying given filter' },
    search = { 'Live issue search' },
    reload = { 'Reload issue. Same as doing e!' },
    browser = { 'Open current issue in the browser' },
    url = { 'Copies the URL of the current issue to the system clipboard' },
  },
  pr = {
    list = { '[repo] [key=value]', 'List all PRs satisfying given filter' },
    search = { 'Live issue search' },
    edit = { '[repo]', 'Edit PR <number> in current or specified repo' },
    reopen = { 'Reopen the current PR' },
    close = { 'Close the current PR' },
    checkout = { 'Checkout PR' },
    commits = { 'List all PR commits' },
    changes = { 'Show all PR changes (diff hunks)' },
    diff = { 'Show PR diff' },
    merge = { '[commit|rebase|squash] [delete]', 'Merge current PR using the specified method' },
    ready = { 'Mark a draft PR as ready for review' },
    checks = { 'Show the status of all checks run on the PR' },
    reload = { 'Reload PR. Same as doing e!' },
    browser = { 'Open current PR in the browser' },
    url = { 'Copies the URL of the current PR to the system clipboard' },
  },
  repo = {
    list = { 'List repos user owns, contributes or belong to' },
    fork = { 'Fork repo' },
    browser = { 'Open current repo in the browser' },
    url = { 'Copies the URL of the current repo to the system clipboard' },
  },
  gist = {
    list = { '[repo] [key=value]', 'List user gists' },
  },
  comment = {
    add = { 'Add a new comment' },
    delete = { 'Delete a comment' },
  },
  thread = {
    resolve = { 'Mark a review thread as resolved' },
    unresolve = { 'Mark a review thread as unresolved' },
  },
  label = {
    add = { 'Add a label from available label menu' },
    remove = { 'Remove a label' },
    create = { 'Create a new label' },
  },
  assignees = {
    add = { 'Assign a user' },
    remove = { 'Unassign a user' },
  },
  reviewer = {
    add = { 'Assign a PR reviewer' },
  },
  reaction = {
    thumbs_up = { 'Add 👍 reaction' },
    thumbs_down = { 'Add 👎 reaction' },
    eyes = { 'Add 👀 reaction' },
    laugh = { 'Add 😄 reaction' },
    confused = { 'Add 😕 reaction' },
    rocket = { 'Add 🚀 reaction' },
    heart = { 'Add ❤️ reaction' },
    hooray = { 'Add 🎉 reaction' },
    party = { 'Add 🎉 reaction' },
    tada = { 'Add 🎉 reaction' },
  },
  card = {
    add = { 'Assign issue/PR to a project new card' },
    remove = { 'Delete project card' },
    move = { 'Move project card to different project/column' },
  },
  review = {
    start = { 'Start a new review' },
    submit = { 'Submit the review' },
    resume = { 'Edit a pending review for current PR' },
    discard = { 'Deletes a pending review for current PR if any' },
    comments = { 'View pending review comments' },
  },
}

local function base_picker(cmd, items)
  return function(opts)
    local results = {}
    for name, infos in pairs(items) do
      if #infos < 2 then
        table.insert(infos, 1, '')
      end
      table.insert(results, { name, infos[1], infos[2] })
    end

    local displayer = entry_display.create {
      separator = ' ',
      items = {
        { width = 15 },
        { width = 35 },
        { remaining = true },
      },
    }

    local make_display = function(entry)
      local item = entry.item
      return displayer {
        item[1],
        item[2],
        item[3],
      }
    end

    pickers.new(opts, {
      prompt_title = 'Octo commands: ' .. cmd,
      sorter = conf.generic_sorter(opts),
      finder = finders.new_table {
        results = results,
        entry_maker = function(item)
          return {
            ordinal = item[1],
            display = make_display,
            item = item,
          }
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd [[stopinsert]]
          vim.fn.feedkeys(':Octo ' .. cmd .. ' ' .. selection.item[1] .. ' ')
        end)
        return true
      end,
    }):find()
  end
end

local octo_pickers = {
  issue = base_picker('issue', commands.issue),
  pr = base_picker('pr', commands.pr),
  repo = base_picker('repo', commands.repo),
  gist = base_picker('gist', commands.gist),
  comment = base_picker('comment', commands.comment),
  thread = base_picker('thread', commands.thread),
  label = base_picker('label', commands.label),
  assignees = base_picker('assignees', commands.assignees),
  reviewer = base_picker('reviewer', commands.reviewer),
  reaction = base_picker('reaction', commands.reaction),
  card = base_picker('card', commands.card),
  review = base_picker('review', commands.review),
}

local function octo_commands(opts)
  opts = vim.tbl_extend('force', themes.get_dropdown(), opts or {})
  local results = vim.tbl_keys(octo_pickers)

  pickers.new(opts, {
    prompt_title = 'Octo commands',
    sorter = conf.generic_sorter(opts),
    finder = finders.new_table {
      results = results,
    },
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.defer_fn(octo_pickers[selection.value], 50)
      end)
      return true
    end,
  }):find()
end

return require('telescope').register_extension {
  exports = {
    octo_commands = octo_commands,
  },
}
