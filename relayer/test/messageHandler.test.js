const chai = require("chai")
const sinon = require("sinon")
const { expect } = chai
const { MessageHandler } = require("../MessageHandler")
const { EIP712Validator } = require("../helpers/EIP712Validator")
const gasEstimator = require("../helpers/gasEstimator")
describe("MessageHandler", () => {
    //Reusable hardcoded data
    const message = {
        user: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        tokenAddress: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
        to: "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec",
        amount: { type: "BigNumber", hex: "0x15af1d78b58c400000" },
        nonce: 67,
    }
    const signature =
        "0xa863bdfd8f36bbb3d242eaefbe7991cbfd411a7e3168e637ebb94ab61e7ebdae749e28dfeeb30748f53b4bf1789b43640e9315ed59680b953dbb6f720716403b1c"

    afterEach(() => {
        sinon.restore()
    })

    describe("addMessage()", () => {
        it("should add a valid message and signature", async () => {
            const messageHandler = new MessageHandler()

            const validateMessageStub = sinon
                .stub(EIP712Validator.prototype, "validateMessage")
                .returns(true)

            const result = await messageHandler.addMessage(message, signature)

            expect(validateMessageStub.calledOnce).to.be.true
            expect(result.success).to.be.true
            expect(result.message).to.equal("Transaction added to batch")
        })

        it("should not add an invalid message and signature", async () => {
            const messageHandler = new MessageHandler()

            //Increasing the nonce by 1
            const messageNonceIncreased = {
                user: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
                tokenAddress: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
                to: "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec",
                amount: { type: "BigNumber", hex: "0x15af1d78b58c400000" },
                nonce: 67 + 1,
            }

            const validateMessageStub = sinon
                .stub(EIP712Validator.prototype, "validateMessage")
                .returns(false)

            const result = await messageHandler.addMessage(messageNonceIncreased, signature)

            expect(validateMessageStub.calledOnce).to.be.true
            expect(result.success).to.be.false
            expect(result.message).to.equal("Invalid message or signature")
        })

        it("should not add to batch because too much gas", async () => {
            const messageHandler = new MessageHandler()

            messageHandler.currentGas = 999999

            const result = await messageHandler.addMessage(message, signature)
            expect(result.success).to.be.false
            expect(result.message).to.equal("Batch already full")
        })
    })

    describe("getBatch()", () => {
        it("should return the current batch with submitted messages", () => {
            const messageHandler = new MessageHandler()
            messageHandler.messages = ["message1", "message2"]
            messageHandler.signatures = ["signature1", "signature2"]
            const batch = messageHandler.getBatch()

            expect(batch).to.deep.equal({
                messages: ["message1", "message2"],
                signatures: ["signature1", "signature2"],
            })
        })
    })

    describe("clearBatch()", () => {
        beforeEach(async () => {
            const messageHandler = new MessageHandler()

            await messageHandler.addMessage(message, signature)
        })

        it("should clear the current batch and reset the internal state", () => {
            const messageHandler = new MessageHandler()

            messageHandler.clearBatch()

            expect(messageHandler.messages).to.be.empty
            expect(messageHandler.signatures).to.be.empty
            expect(messageHandler.currentGas).to.equal(0)
        })
    })
})
