const { expect } = require("chai")
const sinon = require("sinon")
const { BatchHandler } = require("../BatchHandler")

describe("BatchHandler", () => {
    describe("sendBatch()", () => {
        it("should send a batch and return a success message", async () => {
            const batchHandler = new BatchHandler()
            const batch = {
                messages: [
                    "0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f05120000000000000000000000001cbd3b2770909d4e10f157cabc84c7264073c9ec000000000000000000000000000000000000000000000015af1d78b58c4000000000000000000000000000000000000000000000000000000000000000000043",
                ],
                signatures: [
                    "0xa863bdfd8f36bbb3d242eaefbe7991cbfd411a7e3168e637ebb94ab61e7ebdae749e28dfeeb30748f53b4bf1789b43640e9315ed59680b953dbb6f720716403b1c",
                ],
            }

            const result = await batchHandler.sendBatch(batch)
            expect(result.success).to.be.true
            expect(result.message).to.contain(`Batch sent successfully with txn hash:`)
        })

        it("should return an error message if the batch is empty", async () => {
            const batchHandler = new BatchHandler()
            const batch = {
                messages: [],
                signatures: [],
            }

            const result = await batchHandler.sendBatch(batch)

            expect(result.success).to.be.false
            expect(result.message).to.equal("Batch must contain at least 1 transactions")
        })

        it("should return an error message if the length does not match", async () => {
            const batchHandler = new BatchHandler()
            const batch = {
                messages: ["message1"],
                signatures: [],
            }

            const result = await batchHandler.sendBatch(batch)

            expect(result.success).to.be.false
            expect(result.message).to.equal("Length of the messages and signatures mismatch")
        })

        it("should handle errors in sending the batch", async () => {
            const batchHandler = new BatchHandler()
            const batch = {
                messages: ["message1", "message2"],
                signatures: ["signature1", "signature2"],
            }

            const result = await batchHandler.sendBatch(batch)

            expect(result.success).to.be.false
            expect(result.message).to.equal("Error sending batch")
        })
    })
})
