import dotenv from "dotenv";
import {
  createWalletClient,
  http,
  encodeFunctionData,
  zeroAddress,
  toHex,
  getAddress,
  type Chain,
  parseEther,
} from "viem";
import { sepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { batchCallerABI, BATCH_CALLER_ADDRESS } from "./contract";
import {
  EOA_MULTISEND_ADDRESS,
  type MetaTransaction,
  encodeMulti,
} from "./multisend";

function printHash(chain: Chain, hash: `0x${string}`) {
  const explorer = chain.blockExplorers?.default;
  console.log("  Tx Receipt:", explorer?.url + "/tx/" + hash);
}

async function batchCall(pk: `0x${string}`, calls: MetaTransaction[]) {
  console.log("Batch Call");
  const account = privateKeyToAccount(pk);

  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(),
  });
  const authorization = await walletClient.signAuthorization({
    executor: "self",
    contractAddress: BATCH_CALLER_ADDRESS,
  });

  const hash = await walletClient.sendTransaction({
    authorizationList: [authorization],
    data: encodeFunctionData({
      abi: batchCallerABI,
      functionName: "execute",
      args: [
        calls.map((c) => ({
          to: getAddress(c.to),
          value: BigInt(c.value),
          data: c.data as `0x${string}`,
        })),
      ],
    }),
    to: walletClient.account.address,
  });
  printHash(walletClient.chain, hash);
}

async function eoaMultisend(pk: `0x${string}`, calls: MetaTransaction[]) {
  console.log("EOA Multisend");
  const account = privateKeyToAccount(pk);

  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(),
  });
  const authorization = await walletClient.signAuthorization({
    executor: "self",
    contractAddress: EOA_MULTISEND_ADDRESS,
  });

  const hash = await walletClient.sendTransaction({
    authorizationList: [authorization],
    data: encodeMulti(calls),
    to: walletClient.account.address,
  });
  printHash(walletClient.chain, hash);
}

const run = async (): Promise<void> => {
  dotenv.config();
  let privateKey = process.env.PK as `0x${string}`;
  if (!privateKey) {
    console.warn("Missing PK, using dummy account");
    privateKey =
      "0xe4dc8cbe94cbc139084c9c7adc5c2a829d3246f76282679e0c067147a47eb3f8";
  }

  const calls = [
    {
      to: zeroAddress,
      value: toHex(parseEther("0.00001")),
      data: "0x",
    },
    {
      to: "0x1111111111111111111111111111111111111111",
      value: toHex(parseEther("0.00002")),
      data: "0x",
    },
  ];
  // This is the human readable version of the multisend call
  // await batchCall(privateKey, calls);

  // This is compact - gas efficient representation.
  await eoaMultisend(privateKey, calls);
};

run();
