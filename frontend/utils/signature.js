import networkMapping from "@constants/networkMapping"

export const signEIP712Message = async (message, signer) => {
    const chainId = await signer.getChainId()
    const types = {
        Transaction: [
            { name: "user", type: "address" },
            { name: "rfsId", type: "uint256" },
            { name: "makerAddress", type: "address" },
            { name: "paypalEmail", type: "string" },
            { name: "amountToBuy", type: "uint256" },
            { name: "nonce", type: "uint256" },
        ],
    }

    const domain = {
        name: "OTC Swap Protocol",
        version: "1",
        chainId: chainId,
        verifyingContract: networkMapping[chainId].receiver,
    }
    const value = {
        user: message.user,
        rfsId: message.rfsId,
        makerAddress: message.makerAddress,
        paypalEmail: message.paypalEmail,
        amountToBuy: message.amountToBuy,
        nonce: message.nonce,
    }

    console.log(value)
    if (typeof window.ethereum !== "undefined") {
        try {
            const signature = await signer._signTypedData(domain, types, value)
            return signature
        } catch (error) {
            console.error("Error signing EIP712 message:", error)
            throw error
        }
    } else {
        throw new Error("MetaMask not detected")
    }
}

export const submitSignedMessage = async (message, signature) => {
    try {
        const response = await fetch("http://localhost:4000/submit", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({ message, signature }),
        })
        if (!response.ok) {
            const errorText = await response.text()
            return { success: false, message: errorText }
        } else {
            const successText = await response.text()
            return { success: true, message: successText }
        }
    } catch (error) {
        console.error("Error submitting signed message:", error)
        throw error
    }
}
