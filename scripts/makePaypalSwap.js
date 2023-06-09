const ethers = require("ethers")
require("dotenv").config()
const OtcNexusAbi = require("../frontend/constants/abis/OtcNexusAbi")
const PRIVATE_KEY = process.env.PRIVATE_KEY
const provider = new ethers.providers.JsonRpcProvider(process.env.MUMBAI_RPC_URL)

const wallet = new ethers.Wallet(PRIVATE_KEY, provider)

const CONTRACT_ADDRESS = "0x9A2Ea0b2193F95e06d404D5ec86B6EE0847EaE8F"
const ABI = OtcNexusAbi

const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet)

const id = process.argv[2]

const token0Bought = 100
const takerAddress = "0x5103e399eaa2d0851dba00ad2c026cf75cc062ab"

async function sendTransaction() {
  const tx = await contract.takeDynamicRfsPaypal(id, token0Bought, takerAddress)
  console.log("Transaction hash: ", tx.hash)

  const receipt = await tx.wait()
  console.log("Transaction was mined in block ", receipt.blockNumber)
}

sendTransaction().catch(console.error)
