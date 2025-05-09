import dotenv from "dotenv";
import { createWalletClient, http, parseEther, encodeFunctionData, zeroAddress } from "viem";
import { sepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { batchCallerABI, contractAddress } from "./contract";

dotenv.config();
let privateKey = process.env.PK;
if (!privateKey) {
  console.warn("Missing PK, using dummy account");
  privateKey = "0xe4dc8cbe94cbc139084c9c7adc5c2a829d3246f76282679e0c067147a47eb3f8"
}
const account = privateKeyToAccount(privateKey as `0x${string}`);

export const walletClient = createWalletClient({
  account,
  chain: sepolia,
  transport: http(),
});

const run = async (): Promise<void> => {
  const authorization = await walletClient.signAuthorization({
    executor: "self",
    contractAddress,
  });

  const hash = await walletClient.sendTransaction({
    authorizationList: [authorization],
    data: encodeFunctionData({
      abi: batchCallerABI,
      functionName: "execute",
      args: [
        [
          {
            to: zeroAddress,
            value: 1n,
            data: "0x",
          },
          {
            to: "0x1111111111111111111111111111111111111111",
            value: 2n,
            data: "0x",
          },
        ],
      ],
    }),
    to: walletClient.account.address,
  });
  console.log("Batch Call with Hash", hash);
};

run();
