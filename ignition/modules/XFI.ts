import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const XFIModule = buildModule("XFIModule", (m) => {
  const xfi = m.contract("XFI");

  return { xfi };
});

export default XFIModule;
