return {
  { -- Opencode agent
    "NickvanDyke/opencode.nvim",
    event = "VeryLazy",
    ---@type opencode.Opts
    opts = {},
    keys = {
      {
        "<leader>aoo",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle",
      },
      {
        "<leader>aoa",
        function()
          require("opencode").ask("@cursor: ")
        end,
        desc = "Ask ",
        mode = "n",
      },
      {
        "<leader>aoa",
        function()
          require("opencode").ask("@selection: ")
        end,
        desc = "Ask About Selection",
        mode = "v",
      },
      {
        "<leader>aop",
        function()
          require("opencode").select_prompt()
        end,
        desc = "Select Prompt",
        mode = { "n", "v" },
      },
      {
        "<leader>aon",
        function()
          require("opencode").command("session_new")
        end,
        desc = "New Session",
      },
      {
        "<leader>aoy",
        function()
          require("opencode").command("messages_copy")
        end,
        desc = "Yank Last Message",
      },
    },
  },
  { -- tell which-key about the keymaps
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "+ai" },
        { "<leader>ao", group = "+opencode" },
      },
    },
  },
}
