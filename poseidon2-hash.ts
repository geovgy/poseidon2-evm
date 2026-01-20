import { poseidon2Hash } from "@zkpassport/poseidon2"
import { toHex } from "viem";

// This script reads an array of numbers from the command line (FFI), hashes them, and prints the hash.

async function main() {
  // Read the arguments passed to the script (skip node + script name)
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error("Usage: bun poseidon2-hash.ts <num1> <num2> ...");
    process.exit(1);
  }

  // Parse arguments as BigInts
  let inputArr: bigint[] = [];
  try {
    inputArr = args.map((s: string) => BigInt(s));
  } catch (e) {
    console.error("Error parsing inputs:", e);
    process.exit(1);
  }

  // Hash with poseidon2
  try {
    const hash = poseidon2Hash(inputArr);
    console.log(toHex(hash, { size: 32 }));
  } catch (e) {
    console.error("Error computing Poseidon2 hash:", e);
    process.exit(1);
  }
}

main().catch(e => {
  console.error("Unexpected error:", e);
  process.exit(1);
});