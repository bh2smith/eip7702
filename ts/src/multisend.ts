import {
  decodeFunctionData,
  encodeFunctionData,
  encodePacked,
  getAddress,
  parseAbi,
  size,
  toHex,
} from "viem";
import type { Hex, Address } from "viem";

/**
 * Enum representing the type of operation in a meta-transaction.
 */
export enum OperationType {
  /** Standard call operation (0). */
  Call = 0,
  /** Delegate call operation (1). */
  DelegateCall = 1,
}

/**
 * Represents a meta-transaction, which includes the destination address, value, data, and type of operation.
 */
export interface MetaTransaction {
  /** The destination address for the meta-transaction. */
  readonly to: string;
  /** The value to be sent with the transaction (as a string to handle large numbers). */
  readonly value: string; // TODO: Change to hex string! No Confusion.
  /** The encoded data for the contract call or function execution. */
  readonly data: string;
}

export const EOA_MULTI_SEND_ABI = ["function execute(bytes memory calls)"];
export const MULTI_SEND_ABI = ["function multiSend(bytes memory transactions)"];

export const EOA_MULTISEND_ADDRESS =
  "0xDa51eBfBb740D2183e91FAf762666B169A1A9a62";

/// Encodes the transaction as packed bytes of:
/// - `operation` as a `uint8` with `0` for a `call` or `1` for a `delegatecall` (=> 1 byte),
/// - `to` as an `address` (=> 20 bytes),
/// - `value` as a `uint256` (=> 32 bytes),
/// -  length of `data` as a `uint256` (=> 32 bytes),
/// - `data` as `bytes`.
export const encodeMetaTx = (tx: MetaTransaction): Hex =>
  encodePacked(
    ["uint8", "address", "uint256", "uint256", "bytes"],
    [
      OperationType.Call,
      tx.to as Address,
      BigInt(tx.value),
      BigInt(size(tx.data as Hex)),
      tx.data as Hex,
    ],
  );

const remove0x = (hexString: Hex): string => hexString.slice(2);

// Encodes a batch of module transactions into a single multiSend module transaction.
export function encodeMulti(calls: readonly MetaTransaction[]): Hex {
  const encodedCalls = "0x" + calls.map(encodeMetaTx).map(remove0x).join("");
  return encodeFunctionData({
    abi: parseAbi(EOA_MULTI_SEND_ABI),
    functionName: "execute",
    args: [encodedCalls as Hex],
  });
}

function unpack(
  packed: string,
  startIndex: number,
): {
  operation: number;
  to: string;
  value: string;
  data: string;
  endIndex: number;
} {
  // read operation from first 8 bits (= 2 hex digits)
  const operation = parseInt(packed.substring(startIndex, startIndex + 2), 16);
  // the next 40 characters are the to address
  const to = getAddress(
    `0x${packed.substring(startIndex + 2, startIndex + 42)}`,
  );
  // then comes the uint256 value (= 64 hex digits)
  const value = toHex(
    BigInt(`0x${packed.substring(startIndex + 42, startIndex + 106)}`),
  );
  // and the uint256 data length (= 64 hex digits)
  const hexDataLength = parseInt(
    packed.substring(startIndex + 106, startIndex + 170),
    16,
  );
  const endIndex = startIndex + 170 + hexDataLength * 2; // * 2 because each hex item is represented with 2 digits
  const data = `0x${packed.substring(startIndex + 170, endIndex)}`;
  return {
    operation,
    to,
    value,
    data,
    endIndex,
  };
}

export function decodeMulti(data: Hex): MetaTransaction[] {
  const tx = decodeFunctionData({
    abi: parseAbi(MULTI_SEND_ABI),
    data,
  });
  const [transactionsEncoded] = tx.args as [string];
  const result = [];
  let startIndex = 2; // skip over 0x
  while (startIndex < transactionsEncoded.length) {
    const { endIndex, ...tx } = unpack(transactionsEncoded, startIndex);
    result.push(tx);
    startIndex = endIndex;
  }
  return result;
}
