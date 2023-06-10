const ethers = require("ethers")
require("dotenv").config()
const OtcNexusAbi = require("../../frontend/constants/abis/OtcNexusAbi")
const PRIVATE_KEY = process.env.PRIVATE_KEY
const provider = new ethers.providers.JsonRpcProvider(process.env.MUMBAI_RPC_URL)

const wallet = new ethers.Wallet(PRIVATE_KEY, provider)

const CONTRACT_ADDRESS = "0xbF40Cbb12e0Aef9c2700fCb0C698e992161C5362"
const ABI = OtcNexusAbi

const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet)

const id = process.argv[2]

const token0Bought = "0.01"
const takerAddress = "0x5103e399eAA2D0851DbA00ad2c026cf75cC062AB"

async function sendTransaction() {
  const tx = await contract.takeDynamicRfsPaypal(id, ethers.utils.parseEther(token0Bought), takerAddress)
  console.log("Transaction hash: ", tx.hash)

  const receipt = await tx.wait()
  console.log("Transaction was mined in block ", receipt.blockNumber)
}

sendTransaction().catch(console.error)
