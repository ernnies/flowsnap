require('dotenv').config();
const { ProgramManager } = require('@provablehq/aleo-sdk');

async function main() {
  const manager = new ProgramManager();
  await manager.setAccount(process.env.PRIVATE_KEY);

  const programs = [
    { name: "common", path: "./src/common.leo" },
    { name: "flow_core", path: "./src/flow_core.leo" },
  ];

  for (const p of programs) {
    console.log(`Building & deploying ${p.name}...`);
    await manager.buildProgram(p.path);
    const tx = await manager.deployProgram(p.name, p.path, { fee: 600000 });
    console.log(`${p.name} → ${tx}`);
  }
}

main().catch(console.error);