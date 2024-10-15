local M = {}

-- default config
M.config = {
  env_patterns = {
    javascript = {
      { pattern = "process%.env%.([%w_]+)",                             prefix = "process.env." },
      { pattern = "import%.meta%.env%.([%w_]+)",                        prefix = "import.meta.env." },
      { pattern = "import { ([%w_,%s]+) } from '%$env/static/private'", prefix = "$env/static/private." }
    },
    typescript = {
      { pattern = "process%.env%.([%w_]+)",                             prefix = "process.env." },
      { pattern = "import%.meta%.env%.([%w_]+)",                        prefix = "import.meta.env." },
      { pattern = "import { ([%w_,%s]+) } from '%$env/static/private'", prefix = "$env/static/private." }
    },
    go = {
      { pattern = "os%.Getenv%(\"([%w_]+)\"",       prefix = 'os.Getenv("' },
      { pattern = "viper%.GetString%(\"([%w_]+)\"", prefix = 'viper.GetString("' }
    },
  },
  highlight = {
    name = "EnvViewerVirtualText",
    fg = "#FF00FF",
    bg = "NONE",
    style = "bold"
  }
}

function M.read_env_file()
  local env_vars = {}
  local file = io.open('.env', 'r')
  if file then
    for line in file:lines() do
      if not line:match("^%s*#") and line:match("%S") then
        local key, value = line:match("^%s*(%S+)%s*=%s*(.-)%s*$")
        if key and value then
          value = value:gsub("^[\"'](.-)[\"\']$", "%1")
          env_vars[key] = value
        end
      end
    end
    file:close()
  end
  return env_vars
end

function M.setup_highlight()
  local hl = M.config.highlight
  local cmd = string.format(
    "highlight %s guifg=%s guibg=%s gui=%s",
    hl.name, hl.fg, hl.bg, hl.style
  )
  vim.api.nvim_command(cmd)
end

function M.show_env_value()
  local env_vars = M.read_env_file()
  local line = vim.api.nvim_get_current_line()
  local current_line_num = vim.fn.line('.') - 1
  local filetype = vim.bo.filetype

  vim.api.nvim_buf_clear_namespace(0, -1, current_line_num, current_line_num + 1)

  if M.config.env_patterns[filetype] then
    local virtual_text = {}

    for _, pattern_info in ipairs(M.config.env_patterns[filetype]) do
      for var_name in line:gmatch(pattern_info.pattern) do
        if env_vars[var_name] then
          local value = env_vars[var_name]
          table.insert(virtual_text, { " ‼️ " .. value, M.config.highlight.name })
        end
      end
    end

    if #virtual_text > 0 then
      vim.api.nvim_buf_set_virtual_text(0, -1, current_line_num, virtual_text, {})
    end
  end
end

function M.show_all_env_values()
  local env_vars = M.read_env_file()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local filetype = vim.bo.filetype

  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)

  if M.config.env_patterns[filetype] then
    for i, line in ipairs(lines) do
      for _, pattern_info in ipairs(M.config.env_patterns[filetype]) do
        for var_name in line:gmatch(pattern_info.pattern) do
          if env_vars[var_name] then
            local value = env_vars[var_name]
            vim.api.nvim_buf_set_virtual_text(0, -1, i - 1, { { " => " .. value, M.config.highlight.name } }, {})
          end
        end
      end
    end
  end
end

function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  M.setup_highlight()

  local augroup = vim.api.nvim_create_augroup("EnvViewer", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    pattern = { "*.js", "*.ts", "*.go" },
    callback = function()
      vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
      M.show_env_value()
    end
  })

  vim.api.nvim_create_user_command("ShowEnvValues", M.show_all_env_values, {})
end

return M
