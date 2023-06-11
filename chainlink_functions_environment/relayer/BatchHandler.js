const { ethers } = require("ethers")
const path = require("path")
const receiverAbi = require("../../out/Receiver.sol/Receiver.json").abi
const dotenv = require("dotenv")

dotenv.config({ path: path.join(__dirname, "..", ".env") })

const RECEIVER_ADDRESS = process.env.RECEIVER_ADDRESS || ""
const PRIVATE_KEY = process.env.PRIVATE_KEY || ""

class BatchHandler {
  //Initialize the batch handler with the provider, signer, and receiver contract
  //To be used for sending the batch to the receiver
  constructor() {
    this.provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL || "http://localhost:8545")
    this.signer = new ethers.Wallet(PRIVATE_KEY, this.provider)
    this.receiverContract = new ethers.Contract(RECEIVER_ADDRESS, receiverAbi, this.provider).connect(this.signer)
    this.receiverContract.setRelayer(this.signer.address)
  }

  async sendBatch(batch) {
    //Check if the batch has at least 1 message and signature, and they have the same length
    if (batch.messages.length !== batch.signatures.length) {
      return { success: false, message: "Length of the messages and signatures mismatch" }
    }
    if (batch.messages.length >= 1) {
      try {
        const tx = await this.receiverContract.executeMetaTransaction(
          batch.messages,
          batch.signatures,
          //Not required, but can be used to set the gas limit
          {
            gasLimit: 1000000,
          }
        )
        console.log(`Sent batch transaction: ${tx.hash}`)
        await tx.wait()
        console.log(`Batch transaction confirmed: ${tx.hash}`)
        return {
          success: true,
          message: `Batch sent successfully with txn hash: ${tx.hash}`,
        }
      } catch (error) {
        // console.error("Error sending batch", error)
        return { success: false, message: "Error sending batch" }
      }
    } else {
      return { success: false, message: "Batch must contain at least 1 transactions" }
    }
  }
}

module.exports = { BatchHandler }
