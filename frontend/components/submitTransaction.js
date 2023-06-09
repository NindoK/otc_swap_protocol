import React, { useState, useEffect, useRef } from "react"
import { signEIP712Message, submitSignedMessage } from "../utils/signature"
import receiverAbiJson from "../constants/receiverContract.json"
import { ethers } from "ethers"
import networkMapping from "../constants/networkMapping"
import { fetchBatchedTransactions } from "../utils/transactions"

const SubmitTransactionPage = ({ transactions, setTransactions }) => {
    const [rfsId, setRfsId] = useState("")
    const [amountToBuy, setAmountToBuy] = useState("")
    const [paypalEmail, setPaypalEmail] = useState("")
    const [makerAddress, setMakerAddress] = useState("")
    const [submitError, setSubmitError] = useState(null)
    const [isConnected, setIsConnected] = useState(false)
    const rfsIdRef = useRef("")
    const amountToBuyRef = useRef("")
    const paypalEmailRef = useRef("")
    const makerAddressRef = useRef("")
    let signer, provider, receiverAddress, signerAddress

    //Check if the wallet is connected
    const checkConnection = async () => {
        if (window.ethereum) {
            const accounts = await window.ethereum.request({ method: "eth_accounts" })
            setIsConnected(accounts.length > 0)
        }
    }

    // Whenever the state changes, update the ref
    useEffect(() => {
        rfsIdRef.current = rfsId
        amountToBuyRef.current = amountToBuy
        paypalEmailRef.current = paypalEmail
        makerAddressRef.current = makerAddress
    }, [rfsId, amountToBuy, paypalEmail, makerAddress])

    //useEffect to listen to changes in the wallet connection (just to disable/enable button)
    useEffect(() => {
        checkConnection()

        const handleAccountsChanged = (accounts) => {
            setIsConnected(accounts.length > 0)
        }

        if (window.ethereum) {
            window.ethereum.on("accountsChanged", handleAccountsChanged)
        }

        return () => {
            if (window.ethereum) {
                window.ethereum.removeListener("accountsChanged", handleAccountsChanged)
            }
        }
    }, [])

    //Retrieve the nonce of the user from the receiver contract
    async function getNonce(userAddress, contract) {
        try {
            const nonce = await contract.nonceOf(userAddress)
            return nonce.toNumber()
        } catch (error) {
            console.error("Error getting nonce:", error)
            throw error
        }
    }

    // Sign and submit a transaction by accepting a JSON object which contains the transaction details
    const signAndSubmitTransaction = async (json) => {
        try {
            // Sign the EIP-712 message with MetaMask
            const signature = await signEIP712Message(json, signer)

            // Submit the signed message to the relayer
            const { success, message } = await submitSignedMessage(json, signature)

            return { success: success, message: message }
        } catch (error) {
            console.log(error)
            return { success: false, message: "Error signing transaction" }
        }
    }
    const performTransaction = async (payer_id, order_id) => {
        // Instantiate a Web3 provider and retrieve the signer
        provider = new ethers.providers.Web3Provider(window.ethereum)
        signer = provider.getSigner()
        const chainId = await signer.getChainId()
        signerAddress = await signer.getAddress()
        if (
            !rfsIdRef.current ||
            !makerAddressRef.current ||
            !paypalEmailRef.current ||
            !amountToBuyRef.current
        ) {
            setSubmitError("Please fill in all fields")
            return
        }

        if (makerAddressRef.current.length !== 42) {
            setSubmitError(
                "Invalid address length. Ethereum addresses should be 42 characters long."
            )
            return
        }

        //Grab the receiver contract address from the networkMapping
        receiverAddress = networkMapping[chainId].receiver
        const receiverContract = new ethers.Contract(receiverAddress, receiverAbiJson, signer)

        // Get the nonce of the user from the receiver contract
        const nonce = await getNonce(signerAddress, receiverContract)

        const json = {
            user: signerAddress,
            rfsId: rfsIdRef.current,
            makerAddress: makerAddressRef.current,
            paypalEmail: paypalEmailRef.current,
            amountToBuy: amountToBuyRef.current,
            nonce: nonce,
        }

        const { success, message } = await signAndSubmitTransaction(json)

        if (!success) {
            setSubmitError(message)
        } else {
            setSubmitError(null)
        }

        //Update page with new transactions
        const data = await fetchBatchedTransactions()
        setTransactions(data)
    }
    const handleSubmit = (e) => {
        e.preventDefault()
        performTransaction()
    }

    return (
        <div>
            <h1 className="py-2 px-4 mt-5 font-bold text-3xl">Submit Transaction</h1>
            <form onSubmit={handleSubmit} className="flex flex-col justify-center">
                <div className="formContainer tokenField">
                    <label htmlFor="tokenToSend" className="labelForm">
                        Amount To Buy:
                    </label>
                    <input
                        type="number"
                        id="tokenToSend"
                        className="inputForm"
                        value={amountToBuy}
                        style={{ color: "black" }}
                        onChange={(e) => setAmountToBuy(e.target.value)}
                    />
                </div>
                <div className="formContainer">
                    <label htmlFor="targetAddress" className="labelForm">
                        Rfs Id:
                    </label>
                    <input
                        type="text"
                        id="targetAddress"
                        className="inputForm"
                        value={rfsId}
                        style={{ color: "black" }}
                        onChange={(e) => setRfsId(e.target.value)}
                    />
                </div>
                <div className="formContainer">
                    <label htmlFor="to" className="labelForm">
                        Paypal Email:
                    </label>
                    <input
                        type="text"
                        id="to"
                        className="inputForm"
                        value={paypalEmail}
                        style={{ color: "black" }}
                        onChange={(e) => setPaypalEmail(e.target.value)}
                    />
                </div>
                <div className="formContainer">
                    <label htmlFor="to" className="labelForm">
                        Maker Address:
                    </label>
                    <input
                        type="text"
                        id="to"
                        className="inputForm"
                        value={makerAddress}
                        style={{ color: "black" }}
                        onChange={(e) => setMakerAddress(e.target.value)}
                    />
                </div>
                <div>{submitError && <p className="errorText">{submitError}</p>}</div>
                <div className="formContainer">
                    <button type="submit" className="formButton" disabled={!isConnected}>
                        Submit
                    </button>
                </div>
            </form>
        </div>
    )
}

export default SubmitTransactionPage
