local _99 = require("99")

local PiProvider = setmetatable({}, { __index = _99.Providers.BaseProvider })

function PiProvider._build_command(_, query, context)
  return {
    "env",
    "PI_SKIP_VERSION_CHECK=1",
    "pi",
    "--print",
    "--no-session",
    "--model",
    context.model,
    "--no-context-files",
    "--no-skills",
    "--no-extensions",
    "--no-approve",
    query,
  }
end

function PiProvider._get_provider_name()
  return "PiProvider"
end

function PiProvider._get_default_model()
  return "openai-codex/gpt-5.6-sol"
end

function PiProvider.fetch_models(callback)
  vim.system({ "pi", "--list-models", "openai-codex" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, "Failed to fetch models from pi")
        return
      end

      local models = {}
      for provider, model in result.stdout:gmatch("([%w-]+)%s+([%w%.-]+)[^\n]*\n") do
        if provider == "openai-codex" then
          table.insert(models, provider .. "/" .. model)
        end
      end
      callback(models, nil)
    end)
  end)
end

return PiProvider
