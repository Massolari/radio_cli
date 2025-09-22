import { Ok, Error } from "./gleam.mjs";

export const stdout = (childProcess) =>
  childProcess.stdout ? new Ok(childProcess.stdout) : new Error()

export const read = (readable) => {
  const chunk = readable.read();
  return chunk ? new Ok(chunk.toString()) : new Error()
}
