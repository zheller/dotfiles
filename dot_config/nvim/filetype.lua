vim.filetype.add({
  filename = {
    [".bashrc.tmpl"] = "bash",
    [".gitconfig.tmpl"] = "gitconfig",
    [".tmux.conf"] = "tmux",
    [".tmux.conf.tmpl"] = "tmux",
    [".zprofile.tmpl"] = "zsh",
    [".zshenv.tmpl"] = "zsh",
    [".zshrc.tmpl"] = "zsh",
    ["dot_bashrc"] = "bash",
    ["dot_gitconfig"] = "gitconfig",
    ["dot_tmux.conf"] = "tmux",
    ["dot_tmux.conf.tmpl"] = "tmux",
    ["dot_zprofile"] = "zsh",
    ["dot_zshenv"] = "zsh",
    ["dot_zshrc"] = "zsh",
  },
  pattern = {
    [".*%.tmpl"] = function(path)
      local basename = vim.fs.basename(path)
      local filetype_map = {
        bashrc = "bash",
        gitconfig = "gitconfig",
        ["tmux.conf"] = "tmux",
        zprofile = "zsh",
        zshenv = "zsh",
        zshrc = "zsh",
      }

      local chezmoi_name = basename:match("^dot_(.+)%.tmpl$")
      if chezmoi_name then
        return filetype_map[chezmoi_name] or chezmoi_name
      end

      local dotfile_name = basename:match("^%.(.+)%.tmpl$")
      if dotfile_name then
        return filetype_map[dotfile_name] or dotfile_name
      end

      return basename:match("%.([^.]+)%.tmpl$")
    end,
    [".*/dot_.*%.json"] = "json",
    [".*/dot_.*%.lua"] = "lua",
    [".*/dot_.*%.sh"] = "sh",
    [".*/dot_.*%.toml"] = "toml",
    [".*/dot_.*%.ya?ml"] = "yaml",
    [".*/dot_.*%.zsh"] = "zsh",
  },
})
