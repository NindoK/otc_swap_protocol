const ethers = require("ethers")
require("dotenv").config()
const OtcNexusAbi = require("../../frontend/constants/abis/OtcNexusAbi")
const PRIVATE_KEY = process.env.PRIVATE_KEY
const provider = new ethers.providers.JsonRpcProvider(process.env.MUMBAI_RPC_URL)

const wallet = new ethers.Wallet(PRIVATE_KEY, provider)

const CONTRACT_ADDRESS = process.env.OTC_NEXUS_ADDRESS
const ABI = OtcNexusAbi

const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet)

const id = process.argv[2]

const token0Bought = "0.01"
const takerAddress = process.env.TAKER_ADDRESS

async function sendTransaction() {
  const tx = await contract.takeDynamicRfsPaypal(id, ethers.utils.parseEther(token0Bought), takerAddress)
  console.log("Transaction hash: ", tx.hash)

  const receipt = await tx.wait()
  console.log("Transaction was mined in block ", receipt.blockNumber)
}

sendTransaction().catch(console.error)
