import type { Plugin } from "@opencode-ai/plugin"

const VENDOR_MODEL = "openai/gpt-6-luna"

export const CommitModelPlugin: Plugin = async () => {
  return {
    config: (config) => {
      if (!process.env.GNARUS_ALLOW_VENDOR_LLM) return
      config.agent ??= {}
      config.agent["commit"] ??= {}
      config.agent["commit"].model = VENDOR_MODEL
    },
  }
}