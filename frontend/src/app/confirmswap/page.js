"use client"
import React, { useCallback, useRef } from "react"
import Sidebar from "@components/Sidebar"
import { useState, useEffect } from "react"
import { Input, Popover, Modal } from "antd"
import { DownOutlined, SettingOutlined } from "@ant-design/icons"
import Image from "next/image"
import axios from "axios"
import { signEIP712Message, submitSignedMessage } from "@utils/signature"
import { HStack, Button, VStack, useToast } from "@chakra-ui/react"
import OtcNexusAbi from "@constants/abis/OtcNexusAbi"
import { ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import coingeckoCachedResponse from "@constants/coingeckoCachedResponse"
import mumbaiAddressesFeedAggregators from "@constants/mumbaiAddressesFeedAggregators"
import FeedAggregatorMumbaiAbi from "@constants/abis/FeedAggregatorMumbaiAbi"
import receiverAbiJson from "@constants/abis/ReceiverAbi"
import IERC20Abi from "@constants/abis/IERC20Abi"
import { PayPalScriptProvider, PayPalButtons } from "@paypal/react-paypal-js"
import { ConnectButton } from "@rainbow-me/rainbowkit"
const initialOptions = {
    "client-id": process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID || "",
    currency: "EUR",
}

const ConfirmSwap = () => {
    const toast = useToast()
    const [tokenData, setTokenData] = useState([])
    const [tokenOneAmount, setTokenOneAmount] = useState(null)
    const [tokenTwoAmount, setTokenTwoAmount] = useState(null)
    const [isOpen, setIsOpen] = useState(false)
    const [tokenOne, setTokenOne] = useState(tokenData[0])
    const [tokenTwo, setTokenTwo] = useState(tokenData[1])
    const [changeToken, setChangeToken] = useState(1)
    const [searchTerm, setSearchTerm] = useState("")
    const [swapRate, setSwapRate] = useState("")
    const [rfs, setRfs] = useState(null)
    const [error, setError] = useState("")
    const amountToBuyRef = useRef(null)
    const amountToBuyWithRef = useRef(null)

    let signer, provider
    const changeAmount = (e) => {
        const value = e.target.value
        const convertedValue = value.replace(",", ".")
        const valid = /^-?\d*[.,]?\d*$/.test(convertedValue)

        if (valid || e.target.value == "") {
            setTokenTwoAmount(convertedValue * swapRate)
            setTokenOneAmount(convertedValue)
        }

        if (convertedValue > ethers.utils.formatUnits(rfs.currentAmount0)) {
            setError("Amount exceeds the current available amount")
        } else {
            setError("")
        }
    }

    useEffect(() => {
        amountToBuyRef.current = tokenOneAmount
        amountToBuyWithRef.current = tokenTwoAmount
    }, [tokenOneAmount, tokenTwoAmount])

    const filteredTokens = tokenData.filter((e) =>
        e.name.toLowerCase().includes(searchTerm.toLowerCase())
    )

    const openModal = (asset) => {
        setChangeToken(asset)
        setIsOpen(true)
    }

    const modifyToken = (e) => {
        setTokenTwo(e)
        setIsOpen(false)
    }
    const fetchTokenData = useCallback(
        async (rfsObject) => {
            try {
                let onlyTokensAccepted, token0
                if (coingeckoCachedResponse) {
                    const tokens = coingeckoCachedResponse.tokens
                    onlyTokensAccepted = tokens.filter((token) =>
                        rfsObject.tokensAccepted.includes(ethers.utils.getAddress(token.address))
                    )
                    token0 = tokens.filter(
                        (token) => rfsObject.token0 === ethers.utils.getAddress(token.address)
                    )[0]
                } else {
                    const response = await axios.get(
                        "https://tokens.coingecko.com/uniswap/all.json"
                    )

                    // Process the response data
                    const tokens = response.data.tokens
                    const onlyTokensAccepted = tokens.filter((token) =>
                        rfsObject.tokensAccepted.includes(ethers.utils.getAddress(token.address))
                    )
                    const token0 = tokens.filter(
                        (token) => rfsObject.token0 === ethers.utils.getAddress(token.address)
                    )[0]
                }
                setTokenData(onlyTokensAccepted)
                setTokenOne(token0)
                setTokenTwo(onlyTokensAccepted[0])
            } catch (error) {
                console.error("Error fetching token data:", error)
            }
        },
        [setTokenData, setTokenOne, setTokenTwo]
    )

    const getRfsData = async () => {
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const chainId = (await provider.getNetwork()).chainId

        const otcNexus = new ethers.Contract(
            networkMapping[chainId].OtcNexus,
            OtcNexusAbi,
            provider
        )
        const rfsId = window.localStorage.getItem("rfsIdSelected")
        const rfsObject = await otcNexus.getRfs(rfsId)
        setRfs(rfsObject)
        fetchTokenData(rfsObject)
    }

    const getCurrentSwapRate = async () => {
        const price = window.localStorage.getItem("currentSelectedPrice")
        let swapRate
        if (price && price !== "N/A") {
            for (let i = 0; i < tokenData.length; i++) {
                if (mumbaiAddressesFeedAggregators[tokenData[i].address]) {
                    const provider = new ethers.providers.Web3Provider(window.ethereum)
                    const contract = new ethers.Contract(
                        mumbaiAddressesFeedAggregators[tokenData[i].address],
                        FeedAggregatorMumbaiAbi,
                        provider
                    )
                    const decimals = await contract.decimals()
                    const priceWithDecimals = await contract.latestAnswer()
                    swapRate = price / (priceWithDecimals / 10 ** decimals)
                }
            }
        } else {
            swapRate = rfs.initialAmount0 / rfs.amount1
        }
        setSwapRate(swapRate)
    }

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

    const handleApprove = async (e) => {
        e.preventDefault()
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const chainId = (await provider.getNetwork()).chainId
        const erc20 = new ethers.Contract(tokenTwo.address, IERC20Abi, signer)
        let tx = await erc20.approve(
            networkMapping[chainId].OtcNexus,
            ethers.utils.parseEther(amountToBuyWithRef.current.toString().slice(0, 18))
        )
        const receipt = await tx.wait()
        if (receipt)
            toast({
                title: "erc20 approved!",
                status: "success",
                duration: 9000,
                isClosable: true,
            })
    }

    const handleSwap = async () => {
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const chainId = (await provider.getNetwork()).chainId
        const otcNexus = new ethers.Contract(networkMapping[chainId].OtcNexus, OtcNexusAbi, signer)
        const index = tokenData.findIndex((e) => e.address === tokenTwo.address)
        let tx
        let receipt
        if (rfs.typeRfs === 0) {
            tx = await otcNexus.takeDynamicRfs(
                rfs.id,
                ethers.utils.parseUnits(amountToBuyWithRef.current.toString().slice(0, 18)),
                index
            )
            receipt = await tx.wait()
            if (receipt)
                toast({
                    title: "swap succeeded!",
                    status: "success",
                    duration: 9000,
                    isClosable: true,
                })
        } else {
            tx = await otcNexus.takeFixedRfs(
                rfs.id,
                ethers.utils.parseUnits(amountToBuyWithRef.current.toString().slice(0, 18)),
                index
            )
            receipt = await tx.wait()
            if (receipt)
                toast({
                    title: "swap succeeded!",
                    status: "success",
                    duration: 9000,
                    isClosable: true,
                })
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
        const signerAddress = await signer.getAddress()

        //Grab the receiver contract address from the networkMapping
        const receiverAddress = networkMapping[chainId].receiver
        const receiverContract = new ethers.Contract(receiverAddress, receiverAbiJson, signer)

        // Get the nonce of the user from the receiver contract
        const nonce = await getNonce(signerAddress, receiverContract)
        const json = {
            user: signerAddress,
            rfsId: rfs.id.toNumber(),
            makerAddress: rfs.maker,
            paypalEmail: "sb-ow4im25993315@personal.example.com", //rfs.paypalAddress,
            amountToBuy: ethers.utils.parseEther(
                amountToBuyWithRef.current.toString().slice(0, 18)
            ),
            nonce: nonce,
        }
        const { success, message } = await signAndSubmitTransaction(json)
    }

    const handleSubmit = (e) => {
        e.preventDefault()
        performTransaction()
    }

    useEffect(() => {
        getCurrentSwapRate()
    }, [tokenData])

    useEffect(() => {
        getRfsData()
    }, [])

    //PAYPAL
    const createOrder = async (data) => {
        // Order is created on the server and the order id is returned
        const response = await fetch("http://localhost:4000/create-order", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                cart: [
                    {
                        sku: "YOUR_PRODUCT_STOCK_KEEPING_UNIT",
                        quantity: "YOUR_PRODUCT_QUANTITY",
                    },
                ],
            }),
        })
        const order = await response.json()
        console.log(order)
        return order.id
    }

    const onApprove = async (data) => {
        // Order is captured on the server and the response is returned to the browser
        console.log(data)
        const { payerID, orderID, facilitatorAccessToken } = data
        const response = await fetch("http://localhost:4000/create-order", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                orderID: orderID,
            }),
        })
        await performTransaction(payerID, orderID)
        let callbackData = await response.json()
        callbackData["payerID"] = payerID
        callbackData["orderID"] = orderID
        callbackData["facilitatorAccessToken"] = facilitatorAccessToken
        return callbackData
    }

    // const completeTransaction = async (payer_id, order_id) => {
    //     await fetch("http://localhost:4000/complete-order", {
    //         method: "POST",
    //         headers: {
    //             "Content-Type": "application/json",
    //         },
    //         body: JSON.stringify({
    //             payerID: payer_id,
    //             orderID: order_id,
    //         }),
    //     })
    // }

    return (
        <div className="flex min-h-screen h-fit w-full bg-black">
            {/* gradient start */}
            <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
            <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
            <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />
            {/* gradient end */}

            <Sidebar />
            <div className="w-full flex flex-col ">
                <div className="w-full flex justify-end py-3 pr-2 z-10">
                    <ConnectButton />
                </div>
                <Modal
                    open={isOpen}
                    footer={null}
                    onCancel={() => setIsOpen(false)}
                    title="Select a token"
                >
                    <div className=" mt-5 flex flex-col border-t-2 border-t-slate-300 gap-2 max-h-80 overflow-y-auto ">
                        <input
                            type="text"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            placeholder="Search token"
                            className="p-2 my-2 mx-2 rounded-md bg-transparent text-gray-400 border-2"
                        />
                        {rfs &&
                            filteredTokens?.map((e, i) => {
                                return (
                                    <div
                                        className=" hover:cursor-pointer hover:bg-[#1f2639] flex justify-start  align-middle pl-5 pt-2 pb-2"
                                        key={i}
                                        onClick={() => modifyToken(e)}
                                    >
                                        <Image
                                            src={e?.logoURI}
                                            alt="logo"
                                            height={10}
                                            width={30}
                                            className="rounded-full mr-1 p-1"
                                        />
                                        <div className=" font-montserrat ml-2 font-medium text-sm">
                                            {e?.name}
                                        </div>
                                        <div className=" ml-2 text-xs font-light text-[#51596f]">
                                            {e?.symbol}
                                        </div>
                                    </div>
                                )
                            })}
                    </div>
                </Modal>
                {rfs && ( // if rfs is not null then render the page else render nothing (null)
                    <div className="w-full flex h-full justify-center items-center">
                        <div className="w-[500px] bg-gray-950 bg-opacity-20 shadow-lg border-opacity-18 border border-gray-600 h-fit rounded-2xl flex flex-col px-10 z-10">
                            <div className="flex justify-between align-middle width-[98%] my-5">
                                <h2 className=" font-montserrat text-white text-xl  font-bold">
                                    Swap
                                </h2>
                                <Popover title="Settings" trigger="click" placement="bottomRight">
                                    <SettingOutlined className="text-[#51586f] font-bold transition duration-300 hover:cursor-pointer hover:rotate-90 hover:text-white" />
                                </Popover>
                            </div>

                            <div className="relative mb-3">
                                <Input
                                    type="text"
                                    placeholder="0"
                                    pattern="^-?\d*[.,]?\d*$"
                                    value={tokenOneAmount}
                                    onChange={changeAmount}
                                />
                                <Input
                                    type="text"
                                    placeholder="0"
                                    pattern="^-?\d*[.,]?\d*$"
                                    value={tokenTwoAmount}
                                    disabled={true}
                                />
                                <div className="absolute min-w-[80px] h-8 bg-[#3a4157] top-[30px] right-[20px] rounded-full flex justify-start align-middle gap-1 font-bold text-base pr-[8px]">
                                    {tokenOne && (
                                        <>
                                            <Image
                                                src={tokenOne?.logoURI}
                                                alt="assetlogoURI"
                                                height={10}
                                                width={30}
                                                className="rounded-full mr-2 p-1"
                                            />
                                            <p className="text-gray-400  mt-1">
                                                {tokenOne?.symbol}
                                            </p>
                                        </>
                                    )}
                                </div>
                                <div
                                    onClick={() => openModal(2)}
                                    className="hover:cursor-pointer  absolute min-w-[80px] h-8 bg-[#3a4157] top-[135px] right-[20px] rounded-full flex justify-start align-middle gap-1 font-bold text-base pr-[8px]"
                                >
                                    {tokenTwo && (
                                        <>
                                            <Image
                                                src={tokenTwo?.logoURI}
                                                alt="assetlogoURI"
                                                height={10}
                                                width={30}
                                                className="rounded-full mr-1 p-1"
                                            />
                                            <p className="text-gray-400  mt-1">
                                                {tokenTwo?.symbol}
                                            </p>
                                        </>
                                    )}
                                    <DownOutlined className="text-gray-300 font-bold mt-2" />
                                </div>

                                <VStack align="start" className=" mb-5 mt-5">
                                    <h2 className=" font-montserrat font-bold text-lg text-white te">
                                        Current swap price :
                                    </h2>
                                    <p className="font-montserrat font-medium text-sm text-gray-400">
                                        {`${swapRate} ${tokenTwo?.symbol}/${tokenOne?.symbol}`}
                                    </p>
                                </VStack>
                                <VStack align="start" className=" mb-5 justify-start ">
                                    <h2 className=" font-montserrat font-bold text-ml text-white">
                                        Maker Address :
                                    </h2>
                                    <p className="font-montserrat font-medium text-sm text-gray-400">
                                        {rfs.maker}
                                    </p>
                                </VStack>
                                {rfs.priceMultiplier != 0 && (
                                    <HStack className=" mb-5">
                                        <h2 className=" font-montserrat font-bold text-lg text-white">
                                            Discount/Premium :
                                        </h2>
                                        <p
                                            className={`font-montserrat font-medium text-sm `}
                                            style={{
                                                color:
                                                    rfs.priceMultiplier > 100
                                                        ? "#ff000"
                                                        : "#00ff00",
                                            }}
                                        >
                                            {rfs.priceMultiplier > 100
                                                ? `+${rfs.priceMultiplier - 100}`
                                                : `-${100 - rfs.priceMultiplier}`}
                                            %
                                        </p>
                                    </HStack>
                                )}
                                {error && (
                                    <div className="w-full flex justify-center mb-5 mt-5">
                                        <p className="text-red-500 font-montserrat font-bold text-sm">
                                            {error}
                                        </p>
                                    </div>
                                )}
                                <div className="w-full flex justify-center mb-5 mt-5">
                                    <Button
                                        onClick={handleApprove}
                                        className="bg-blue-gradient rounded-xl h-fit w-fit py-2  px-14"
                                        style={{ marginRight: "15px" }}
                                    >
                                        Approve
                                    </Button>
                                    <Button
                                        onClick={handleSwap}
                                        className="bg-blue-gradient rounded-xl h-fit w-fit py-2  px-16"
                                    >
                                        Swap
                                    </Button>
                                </div>
                                <PayPalScriptProvider options={initialOptions}>
                                    <PayPalButtons
                                        createOrder={(data) => createOrder(data)}
                                        onApprove={(data) =>
                                            onApprove(data).then((details) => {
                                                console.log(details)
                                                // completeTransaction(details.payerID, details.orderID)
                                            })
                                        }
                                    />
                                </PayPalScriptProvider>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}

export default ConfirmSwap
