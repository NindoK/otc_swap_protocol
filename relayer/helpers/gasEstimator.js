async function estimateTransactionGas(contract, messages, signatures) {
    try {
        const gasEstimate = await contract.estimateGas.executeMetaTransaction(messages, signatures)
        return gasEstimate.toNumber()
    } catch (error) {
        console.error("Error estimating gas:", error)
        return { success: false, message: "Error estimating gas" }
    }
}

module.exports = { estimateTransactionGas }
