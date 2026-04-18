vim.filetype.add({
  filename = {
    ["dot_bashrc"] = "bash",
    ["dot_gitconfig"] = "gitconfig",
    ["dot_zprofile"] = "zsh",
    ["dot_zshenv"] = "zsh",
    ["dot_zshrc"] = "zsh",
  },
  pattern = {
    [".*[/\\]dot_[^/\\]+%.tmpl"] = function(path)
      local name = vim.fs.basename(path):match("^dot_(.+)%.tmpl$")
      local filetype_map = {
        bashrc = "bash",
        gitconfig = "gitconfig",
        zprofile = "zsh",
        zshenv = "zsh",
        zshrc = "zsh",
      }
      return filetype_map[name] or name
    end,
    [".*%.([^.]+)%.tmpl"] = function(_, _, ext)
      return ext
    end,
    [".*/dot_.*%.json"] = "json",
    [".*/dot_.*%.lua"] = "lua",
    [".*/dot_.*%.sh"] = "sh",
    [".*/dot_.*%.toml"] = "toml",
    [".*/dot_.*%.ya?ml"] = "yaml",
    [".*/dot_.*%.zsh"] = "zsh",
  },
})
