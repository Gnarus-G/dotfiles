local _99 = require("99")

local PiProvider = setmetatable({}, { __index = _99.Providers.BaseProvider })

local function parse_models(output)
  local models = {}
  for provider, model in output:gmatch("(%S+)%s+(%S+)[^\n]*") do
    if provider ~= "provider" then
      table.insert(models, provider .. "/" .. model)
    end
  end
  return models
end

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
  return "ollama-cloud/glm-5.2"
end

function PiProvider._get_vendor_model()
  return "openai-codex/gpt-5.6-sol"
end

function PiProvider._has_model(model)
  local result = vim
    .system({
      "env",
      "PI_SKIP_VERSION_CHECK=1",
      "pi",
      "--list-models",
      model,
    }, { text = true })
    :wait()

  if result.code ~= 0 then
    return false
  end
  return vim.tbl_contains(parse_models(result.stdout), model)
end

function PiProvider.fetch_models(callback)
  vim.system({ "pi", "--list-models" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, "Failed to fetch models from pi")
        return
      end

      callback(parse_models(result.stdout), nil)
    end)
  end)
end

return PiProvider
