-- Same LLM proxy that pi uses, with the same API key: chezmoi writes it into
-- pi's models.json from 1Password, so read it from there.
local proxy_api_url = 'https://api.ai.ianpascoe.dev'
local proxy_api_key

local function pi_models_path()
  local agent_dir = vim.env.PI_CODING_AGENT_DIR
  agent_dir = agent_dir and vim.fn.expand(agent_dir) or vim.fs.joinpath(vim.uv.os_homedir(), '.pi', 'agent')
  return vim.fs.joinpath(agent_dir, 'models.json')
end

--- The literal apiKey of a pi provider pointed at the proxy, or nil.
local function read_proxy_api_key()
  local path = pi_models_path()
  local ok, config = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  end)
  if not ok or type(config) ~= 'table' or type(config.providers) ~= 'table' then
    return nil
  end
  for _, provider in pairs(config.providers) do
    local key = provider.apiKey
    if
      type(provider.baseUrl) == 'string'
      and vim.startswith(provider.baseUrl, proxy_api_url)
      and type(key) == 'string'
      and key ~= ''
      and not key:find('^!')
      and not key:find('%$')
    then
      return key
    end
  end
end

local function proxy_key()
  proxy_api_key = proxy_api_key or read_proxy_api_key()
  if not proxy_api_key then
    vim.notify_once(
      'minuet: no API key for ' .. proxy_api_url .. ' in ' .. pi_models_path() .. '; run `chezmoi apply ~/.pi/agent/models.json`',
      vim.log.levels.WARN
    )
    return ''
  end
  return proxy_api_key
end

return {
  {
    'folke/sidekick.nvim',
    ---@module "sidekick"
    ---@type sidekick.Config
    opts = {
      nes = {
        enabled = false,
      },
      copilot = {
        status = {
          enabled = false,
        },
      },
      cli = {
        tools = {
          omp = {
            cmd = { 'omp' },
            is_proc = '\\<omp\\>',
            resume = { '--resume' },
            continue = { '--continue' },
            url = 'https://omp.sh',
            native_scroll = false,
          },
        },
      },
    },
    config = function(_, opts)
      require('sidekick').setup(opts)
      if vim.env.HERDR_ENV == '1' and vim.fn.executable('herdr') == 1 then
        require('sidekick.cli.session').register('herdr', require('config.sidekick_herdr'))
      elseif vim.env.TERN_PANE and not vim.env.TMUX and vim.fn.executable('tern') == 1 then
        require('sidekick.cli.session').register('tern', require('config.sidekick_tern'))
      elseif vim.env.REX_BLOCK and not vim.env.TMUX and vim.fn.executable('rex') == 1 then
        require('sidekick.cli.session').register('rex', require('config.sidekick_rex'))
      end
    end,
  },
  {
    'milanglacier/minuet-ai.nvim',
    opts = {
      provider = 'openai_compatible',
      request_timeout = 30,
      n_completions = 3,
      throttle = 1500, -- Increase to reduce costs and avoid rate limits
      debounce = 600, -- Increase to reduce costs and avoid rate limits
      provider_options = {
        openai_compatible = {
          api_key = proxy_key,
          end_point = proxy_api_url .. '/chat/completions',
          -- Benchmarked against the proxy's models (2026-10): best speed/accuracy
          -- trade-off. Runner-up: 'hy4-preview' (more accurate, ~2x slower).
          model = 'gemini-3-flash',
          name = 'proxy',
          stream = false,
          transform = {
            function(args)
              args.headers['User-Agent'] = 'minuet-ai.nvim'
              return args
            end,
          },
          optional = {
            max_tokens = 56,
            reasoning_effort = 'none',
          },
        },
      },
    },
  },
  {
    'saghen/blink.cmp',
    optional = true,
    opts = {
      sources = {
        default = { 'minuet' },
        providers = {
          minuet = {
            name = 'minuet',
            module = 'minuet.blink',
            async = true,
            score_offset = 100,
          },
        },
      },
      completion = { trigger = { prefetch_on_insert = false } },
    },
  },
  {
    'nvim-lualine/lualine.nvim',
    optional = true,
    event = 'VeryLazy',
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 2, {
        require('minuet.lualine'),
        icon = '󰚩',
      })
    end,
  },
}
