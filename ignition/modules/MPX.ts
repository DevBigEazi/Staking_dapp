import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MPXModule = buildModule("MPXModule", (m) => {

  const mpx = m.contract("MPX");

  return { mpx };
});

export default MPXModule;