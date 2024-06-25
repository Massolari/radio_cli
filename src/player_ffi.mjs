import { spawn } from "node:child_process"

export const spawn_ = (cmd, args) =>
  spawn(cmd, args.toArray())

