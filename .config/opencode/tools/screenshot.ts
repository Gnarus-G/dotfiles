import { tool } from "@opencode-ai/plugin"

const OUTPUT_DIR = process.env.HOME + "/.local/share/screenshots"

export const take = tool({
  description: "Take a screenshot using KDE Spectacle. Saves to ~/.local/share/screenshots/",
  args: {
    mode: tool.schema.enum(["fullscreen", "current", "active", "window"]).describe("Screenshot mode: fullscreen (entire desktop), current (current monitor), active (active window), window (window under cursor)"),
    delay: tool.schema.number().int().min(0).default(0).optional().describe("Delay before capture in milliseconds"),
    include_base64: tool.schema.boolean().default(false).optional().describe("Include base64-encoded image in output"),
  },
  async execute(args) {
    const modeFlags: Record<string, string> = {
      fullscreen: "-f",
      current: "-m",
      active: "-a",
      window: "-u",
    }

    const timestamp = new Date().toISOString().replace(/[-:T]/g, "").split(".")[0]
    const filename = `screenshot_${timestamp}.png`
    const outputPath = `${OUTPUT_DIR}/${filename}`
    const flag = modeFlags[args.mode]
    const delay = args.delay || 0

    try {
      await Bun.$`mkdir -p ${OUTPUT_DIR}`.quiet()
      
      let cmd: string[]
      if (delay > 0) {
        cmd = ["spectacle", "-b", "-o", outputPath, flag, "-d", String(delay)]
      } else {
        cmd = ["spectacle", "-b", "-o", outputPath, flag]
      }
      
      const result = Bun.spawnSync(cmd, { stdout: "pipe", stderr: "pipe" })
      
      if (result.exitCode !== 0) {
        return JSON.stringify({
          success: false,
          error: `Spectacle failed with exit code ${result.exitCode}: ${result.stderr.toString()}`,
        })
      }

      const file = Bun.file(outputPath)
      if (!(await file.exists())) {
        return JSON.stringify({
          success: false,
          error: `Screenshot file not created at ${outputPath}`,
        })
      }

      const stats = await file.stat()
      const response: Record<string, unknown> = {
        success: true,
        path: outputPath,
        mode: args.mode,
        filename,
        size_bytes: stats?.size || 0,
      }

      if (args.include_base64) {
        const buffer = await file.arrayBuffer()
        response.base64 = Buffer.from(buffer).toString("base64")
      }

      return JSON.stringify(response)
    } catch (error) {
      return JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      })
    }
  },
})

export const list = tool({
  description: "List all saved screenshots",
  args: {},
  async execute() {
    try {
      await Bun.$`mkdir -p ${OUTPUT_DIR}`.quiet()
      
      const result = Bun.spawnSync(
        ["find", OUTPUT_DIR, "-maxdepth", "1", "-name", "*.png", "-type", "f"],
        { stdout: "pipe" }
      )
      
      const files = result.stdout.toString().trim().split("\n").filter(Boolean)
      
      const screenshots = await Promise.all(
        files.map(async (filepath) => {
          const file = Bun.file(filepath)
          const stats = await file.stat()
          return {
            filename: filepath.split("/").pop(),
            path: filepath,
            size_bytes: stats?.size || 0,
            modified: stats?.mtime || new Date(),
          }
        })
      )
      
      screenshots.sort((a, b) => new Date(b.modified).getTime() - new Date(a.modified).getTime())
      
      return JSON.stringify({
        count: screenshots.length,
        directory: OUTPUT_DIR,
        screenshots,
      }, null, 2)
    } catch (error) {
      return JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      })
    }
  },
})
