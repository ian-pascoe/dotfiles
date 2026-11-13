-- The Tailwind server scans the whole workspace for CSS and tsconfig files. In
-- repos with reference clones (.repos/, see the reference-repos skill) or
-- nested worktrees, it hits tsconfigs whose `extends` packages were never
-- installed and logs a resolve error for each. Keep it out of them.
return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        tailwindcss = {
          settings = {
            tailwindCSS = {
              files = {
                -- Replaces the server's default list, so repeat it.
                exclude = {
                  '**/.git/**',
                  '**/node_modules/**',
                  '**/.hg/**',
                  '**/.svn/**',
                  '**/.repos/**',
                  '**/.worktrees/**',
                },
              },
            },
          },
        },
      },
    },
  },
}
