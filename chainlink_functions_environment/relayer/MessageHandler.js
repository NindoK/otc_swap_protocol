const { EIP712Validator } = require("./helpers/EIP712Validator")
const { ethers } = require("ethers")
const { AbiCoder } = require("@ethersproject/abi")
const { estimateTransactionGas } = require("./helpers/gasEstimator")

const path = require("path")
const receiverAbi = require("../../out/Receiver.sol/Receiver.json").abi
const dotenv = require("dotenv")

dotenv.config({ path: path.join(__dirname, "..", ".env") })

const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
const RECEIVER_ADDRESS = process.env.RECEIVER_ADDRESS || ""

class MessageHandler {
  //Initialize the message handler with the provider, signer, and receiver contract
  //Set the max gas limit for a batch
  constructor() {
    this.messages = []
    this.signatures = []
    this.MAX_GAS_LIMIT = 1000000 //Max gas limit for a batch
    this.currentGas = 0

    this.provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL || "http://localhost:8545")
    this.signer = new ethers.Wallet(PRIVATE_KEY, this.provider)
    this.receiverContract = new ethers.Contract(RECEIVER_ADDRESS, receiverAbi, this.provider).connect(this.signer)
  }

  async addMessage(message, signature) {
    if (message === undefined || signature === undefined) {
      return { success: false, message: "Message or signature not provided" }
    }
    const validator = new EIP712Validator()
    if (!validator.validateMessage(message, signature)) {
      return { success: false, message: "Invalid message or signature" }
    }
    const abiCoder = new AbiCoder()

    // Serialize transaction to abi encoded bytes
    const serializedTransaction = abiCoder.encode(
      ["address", "uint256", "address", "string", "uint256", "uint256"],
      [message.user, message.rfsId, message.makerAddress, message.paypalEmail, message.amountToBuy, message.nonce]
    )

    if (this.messages.includes(serializedTransaction)) {
      return { success: false, message: "Transaction already submitted" }
    }

    //Check if the transaction would fail and if the batch would exceed the maximum gas limit
    const gasEstimate = await estimateTransactionGas(this.receiverContract, [serializedTransaction], [signature])
    if (gasEstimate == 0) {
      return { success: false, message: "Transaction would fail" }
    }

    if (this.currentGas + gasEstimate > this.MAX_GAS_LIMIT) {
      // Stop adding transactions to the batch if it would exceed the maximum gas limit
      return { success: false, message: "Batch already full" }
    }
    console.log(gasEstimate)
    //Before returning update the new data and push them to the batch
    this.currentGas += gasEstimate
    this.messages.push(serializedTransaction)
    this.signatures.push(signature)

    return { success: true, message: "Transaction added to batch" }
  }

  getBatch() {
    return {
      messages: this.messages,
      signatures: this.signatures,
    }
  }

  clearBatch() {
    this.messages = []
    this.signatures = []
    this.currentGas = 0
  }
}

module.exports = { MessageHandler }
