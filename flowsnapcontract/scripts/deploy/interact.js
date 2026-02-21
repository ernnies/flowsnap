require('dotenv').config();
const { ProgramManager, PrivateKey } = require('@provablehq/aleo-sdk');

async function main() {
  const manager = new ProgramManager();
  const pk = PrivateKey.from_string(process.env.PRIVATE_KEY);
  await manager.setAccount(pk.to_string());

  const programId = "flow_core.aleo"; // or full program ID after deploy

  console.log("Creating test workflow...");

  const inputs = [
    "Test Yield Strategy",                              // name: string
    ["Swap", "FlashLoan", "AddLiquidity"],              // steps: [string; 16]
    3                                                   // steps_len: u32
  ];

  try {
    const tx = await manager.execute(
      programId,
      "create_workflow",
      inputs,
      {
        fee: 400000,
        privateFee: false,
      }
    );

    console.log("Transaction submitted:", tx);
  } catch (err) {
    console.error("Execution failed:", err);
  }
}

main().catch(console.error);