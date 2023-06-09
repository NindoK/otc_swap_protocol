"use client"
import React, { useCallback } from "react"
import Sidebar from "@components/Sidebar"
import { useState, useEffect } from "react"
import { Input, Popover, Modal } from "antd"
import { DownOutlined, SettingOutlined } from "@ant-design/icons"
import Image from "next/image"
import axios from "axios"
import { HStack, Button, VStack } from "@chakra-ui/react"
import OtcNexusAbi from "@constants/abis/OtcNexusAbi"
import { ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import coingeckoCachedResponse from "@constants/coingeckoCachedResponse"
import mumbaiAddressesFeedAggregators from "@constants/mumbaiAddressesFeedAggregators"
import FeedAggregatorMumbaiAbi from "@constants/abis/FeedAggregatorMumbaiAbi"

const ConfirmSwap = () => {
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

    const changeAmount = (e) => {
        const value = e.target.value
        const convertedValue = value.replace(",", ".")
        const valid = /^-?\d*[.,]?\d*$/.test(convertedValue)

        if (valid || e.target.value == "") {
            setTokenTwoAmount(convertedValue * swapRate)
            setTokenOneAmount(convertedValue)
        }
        if (convertedValue > rfs.currentAmount0.toNumber()) {
            setError("Amount exceeds the current available amount")
        } else {
            setError("")
        }
    }

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

    useEffect(() => {
        getCurrentSwapRate()
    }, [tokenData])

    useEffect(() => {
        getRfsData()
    }, [])

    return (
        <div className="flex h-screen w-full bg-black">
            {/* gradient start */}
            <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
            <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
            <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />
            {/* gradient end */}
            <Sidebar />

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
                            <h2 className=" font-montserrat text-white text-xl  font-bold">Swap</h2>
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
                                        <p className="text-gray-400  mt-1">{tokenOne?.symbol}</p>
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
                                        <p className="text-gray-400  mt-1">{tokenTwo?.symbol}</p>
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
                                            color: rfs.priceMultiplier > 100 ? "#ff000" : "#00ff00",
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
                                <Button className="bg-blue-gradient rounded-xl h-fit w-fit py-2  px-16">
                                    Swap
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}

export default ConfirmSwap
