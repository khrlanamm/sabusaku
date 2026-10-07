import {randomInt} from "node:crypto";

// No 0/O, 1/l/i: initial passwords are read off a list and typed by hand.
const ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789";

/** Random initial password; the user must replace it at first sign-in. */
export function generatePassword(length = 10): string {
  let out = "";
  for (let i = 0; i < length; i++) out += ALPHABET[randomInt(ALPHABET.length)];
  return out;
}
