const chai = require("chai")
const chaiHttp = require("chai-http")
const sinon = require("sinon")
const { expect } = chai
const { ethers } = require("ethers")
const { MessageHandler } = require("../MessageHandler")
const { BatchHandler } = require("../BatchHandler")

chai.use(chaiHttp)

const { app, startApp } = require("../index")

describe("App", () => {
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

    // Test the behavior of the /get-batch endpoint before submitting transactions
    describe("GET /get-batch", () => {
        it("should return an empty batch", async () => {
            const res = await chai.request(app).get("/get-batch")

            expect(res).to.have.status(200)
            expect(res.body).to.deep.equal({ messages: [], signatures: [] })
        })
    })

    // Test the behavior of the /submit endpoint
    describe("POST /submit", () => {
        afterEach(() => {
            sinon.restore()
        })

        it("should not accept a empty body", async () => {
            const res = await chai.request(app).post("/submit").send({})

            expect(res).to.have.status(400)
            expect(res.text).to.equal("Message or signature not provided")
        })

        it("should throw an error", async () => {
            const errorMessage = "An error occurred"

            //Use stub to force an error
            const addMessageStub = sinon
                .stub(MessageHandler.prototype, "addMessage")
                .throws(new Error(errorMessage))

            const res = await chai.request(app).post("/submit").send({ message, signature })
            expect(addMessageStub.calledOnce).to.be.true
            expect(res).to.have.status(400)
            expect(res.text).to.equal(errorMessage)
        })

        it("should not accept a message without a signature", async () => {
            const res = await chai.request(app).post("/submit").send({ message })

            expect(res).to.have.status(400)
            expect(res.text).to.equal("Message or signature not provided")
        })

        it("should not accept a signature without a message", async () => {
            const res = await chai.request(app).post("/submit").send({ signature })

            expect(res).to.have.status(400)
            expect(res.text).to.equal("Message or signature not provided")
        })

        it("should not submit a non valid message and signature", async () => {
            const messageNonceIncreased = {
                user: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
                tokenAddress: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
                to: "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec",
                amount: { type: "BigNumber", hex: "0x15af1d78b58c400000" },
                nonce: 68,
            }
            const res = await chai
                .request(app)
                .post("/submit")
                .send({ message: messageNonceIncreased, signature })

            expect(res).to.have.status(400)
            expect(res.text).to.equal("Invalid message or signature")
        })

        it("should not accept a valid message and a non valid signature", async () => {
            const signatureTruncated =
                "0xa863bdfd8f36bbb3d242eaefbe7991cbfd411a7e3168e637ebb94ab61e7ebdae749e28d"
            const res = await chai
                .request(app)
                .post("/submit")
                .send({ message, signature: signatureTruncated })

            expect(res).to.have.status(400)
            expect(res.text).to.equal("Invalid message or signature")
        })

        it("should submit a valid message and signature", async () => {
            const res = await chai.request(app).post("/submit").send({ message, signature })

            expect(res).to.have.status(200)
            expect(res.text).to.equal("Message submitted")
        })
    })

    // Test the behavior of the /get-batch endpoint after submitting transactions
    describe("GET /get-batch after submitting transaction", () => {
        it("should return a batch with 1 element", async () => {
            const res = await chai.request(app).get("/get-batch")

            expect(res).to.have.status(200)
            expect(res.body).to.deep.equal({
                messages: [
                    "0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f05120000000000000000000000001cbd3b2770909d4e10f157cabc84c7264073c9ec000000000000000000000000000000000000000000000015af1d78b58c4000000000000000000000000000000000000000000000000000000000000000000043",
                ],
                signatures: [
                    "0xa863bdfd8f36bbb3d242eaefbe7991cbfd411a7e3168e637ebb94ab61e7ebdae749e28dfeeb30748f53b4bf1789b43640e9315ed59680b953dbb6f720716403b1c",
                ],
            })
        })
    })

    // Test the behavior of the app starting and each batch sending based on an interval
    describe("startApp", () => {
        let serverInstance

        beforeEach(async () => {
            sinon.restore()
            await chai.request(app).post("/submit").send({ message, signature })
        })

        afterEach((done) => {
            serverInstance.server.close(done)
            clearInterval(serverInstance.interval)
        })

        it("should send a batch and clear it if successful", (done) => {
            const sendBatchStub = sinon.stub(BatchHandler.prototype, "sendBatch")
            sendBatchStub.resolves({ success: true, message: "Batch sent" })

            serverInstance = startApp(800)

            setTimeout(() => {
                expect(sendBatchStub.called).to.be.true
                BatchHandler.prototype.sendBatch.restore()
                done()
            }, 1100)
        }).timeout(1300)

        it("should send a batch and fail", (done) => {
            const sendBatchStub = sinon.stub(BatchHandler.prototype, "sendBatch")
            sendBatchStub.resolves({ success: false, message: "Batch sending failed" })

            const consoleErrorStub = sinon.stub(console, "error")

            serverInstance = startApp(800)

            setTimeout(() => {
                expect(consoleErrorStub.called).to.be.true
                expect(consoleErrorStub.args[0][0]).to.be.equal("Batch sending failed")

                expect(sendBatchStub.called).to.be.true
                BatchHandler.prototype.sendBatch.restore()
                done()
            }, 1100)
        }).timeout(1300)

        it("should not send a batch ", (done) => {
            const sendBatchStub = sinon.stub(BatchHandler.prototype, "sendBatch")
            sendBatchStub.throws(new Error("An error occurred"))
            const consoleErrorStub = sinon.stub(console, "error")

            serverInstance = startApp(800)

            setTimeout(() => {
                expect(consoleErrorStub.called).to.be.true
                expect(consoleErrorStub.args[0][0]).to.equal("Error sending batch")
                expect(consoleErrorStub.args[0][1])
                    .to.be.an("Error")
                    .and.have.property("message", "An error occurred")
                BatchHandler.prototype.sendBatch.restore()
                done()
            }, 1100)
        }).timeout(1300)
    })
})
