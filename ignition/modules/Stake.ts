import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakeModule = buildModule("StakeModule", (m) => {

  const stake = m.contract("Stake");

  return { stake };
});

export default StakeModule;
