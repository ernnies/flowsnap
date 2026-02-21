require('dotenv').config();
const { ProgramManager, AleoKeyProvider } = require('@provablehq/aleo-sdk');

const PRIVATE_KEY = process.env.PRIVATE_KEY; // aleo1... format

if (!PRIVATE_KEY) {
  throw new Error("PRIVATE_KEY not set in .env");
}

async function main() {
  const keyProvider = new AleoKeyProvider();
  const programManager = new ProgramManager();

  await programManager.setAccount(PRIVATE_KEY);

  console.log("Deploying FlowSnap programs...");

  // Order matters: dependencies first
  const deployments = [
    { name: "common", path: "./src/common.leo" },
    { name: "c0mrad_token", path: "./src/c0mrad_token.leo" },
    { name: "flow_core", path: "./src/flow_core.leo" },
    { name: "risk_engine", path: "./src/risk_engine.leo" },
    { name: "yield_optimizer", path: "./src/yield_optimizer.leo" },
    { name: "flash_loan", path: "./src/flash_loan.leo" },
    { name: "insurance_pool", path: "./src/insurance_pool.leo" },
    { name: "c0mrad_dao", path: "./src/c0mrad_dao.leo" },
    { name: "rwa_factory", path: "./src/rwa_factory.leo" },
  ];

  const deployedPrograms = {};

  for (const { name, path } of deployments) {
    console.log(`\nDeploying ${name}...`);
    try {
      // Build first
      await programManager.buildProgram(path);

      // Deploy
      const tx = await programManager.deployProgram(name, path, {
        fee: 500000,           // in microcredits – adjust based on network
        feePrivate: false,
      });

      console.log(`${name} deployed → Transaction ID: ${tx}`);
      deployedPrograms[name] = tx;
    } catch (err) {
      console.error(`Failed to deploy ${name}:`, err);
    }
  }

  console.log("\nDeployment summary:");
  console.table(deployedPrograms);
}

main().catch(console.error);