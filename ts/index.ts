import dotenv from "dotenv";
import { createWalletClient, http, parseEther, encodeFunctionData } from "viem";
import { sepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { batchCallerABI, contractAddress } from "./contract";

dotenv.config();
const privateKey = process.env.PK;
if (!privateKey) {
  console.error("Missing PK!");
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
            to: "0xcb98643b8786950F0461f3B0edf99D88F274574D",
            value: parseEther("0.001"),
            data: "0x",
          },
          {
            to: "0xd2135CfB216b74109775236E36d4b433F1DF507B",
            value: parseEther("0.002"),
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
