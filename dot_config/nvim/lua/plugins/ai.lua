-- Same Cloudflare Access-protected LLM proxy that pi uses (~/.pi/agent/models.json).
local proxy_base_url = 'https://ai.ianpascoe.dev'
local proxy_api_url = 'https://api.ai.ianpascoe.dev'

-- `cloudflared access token` takes ~400ms and minuet's transforms run
-- synchronously, so cache the JWT until shortly before it expires.
local cf_token = { value = nil, exp = 0 }

local function jwt_exp(token)
  local payload = token:match('^[^.]+%.([^.]+)%.')
  if not payload then
    return 0
  end
  payload = payload:gsub('-', '+'):gsub('_', '/')
  payload = payload .. string.rep('=', (4 - #payload % 4) % 4)
  local ok, claims = pcall(function()
    return vim.json.decode(vim.base64.decode(payload))
  end)
  return ok and tonumber(claims.exp) or 0
end

local function cf_access_token()
  if cf_token.value and os.time() < cf_token.exp - 60 then
    return cf_token.value
  end
  local result = vim.system({ 'cloudflared', 'access', 'login', '--no-verbose', '--auto-close', '-app=' .. proxy_base_url }, { text = true }):wait()
  local token = vim.trim(result.stdout or '')
  if result.code ~= 0 or token == '' then
    vim.notify_once('minuet: `cloudflared access token` failed; run `cloudflared access login ' .. proxy_base_url .. '`', vim.log.levels.WARN)
    return ''
  end
  local exp = jwt_exp(token)
  cf_token = { value = token, exp = exp > 0 and exp or os.time() + 300 }
  return token
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
          -- The proxy injects the real key; minuet only needs a non-empty value.
          api_key = function()
            return 'sk-dummy'
          end,
          end_point = proxy_api_url .. '/chat/completions',
          -- Benchmarked against the proxy's models (2026-10): best speed/accuracy
          -- trade-off. Runner-up: 'hy4-preview' (more accurate, ~2x slower).
          model = 'gemini-3-flash',
          name = 'proxy',
          stream = false,
          transform = {
            function(args)
              args.headers['User-Agent'] = 'minuet-ai.nvim'
              args.headers['cf-access-token'] = cf_access_token()
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
