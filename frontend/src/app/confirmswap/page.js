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

import { useRouter } from "next/router"
const ConfirmSwap = (
    {
        // rfsId = 2 /*rfs TODO we can consider just passing the rfs directly, since we already fetch it from the swap page and we have a list of rfs*/,
    }
) => {
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

    const changeAmount = (e) => {
        const value = parseFloat(e.target.value)
        if (!isNaN(value)) {
            setTokenOneAmount(e.target.value)
        }
        //TODO Automatically calculate the correspective token amount given the current swapRate
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
                const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")

                // Process the response data
                const tokens = response.data.tokens
                const onlyTokensAccepted = tokens.filter((token) =>
                    rfsObject.tokensAccepted.includes(ethers.utils.getAddress(token.address))
                )
                const token0 = tokens.filter(
                    (token) => rfsObject.token0 === ethers.utils.getAddress(token.address)
                )[0]
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
        console.log(rfsObject)
        setRfs(rfsObject)
        fetchTokenData(rfsObject)
    }

    const getCurrentSwapRate = async () => {
        //TODO: Implement this
        //Query some API for the current swap rate if it's dynamic and apply rfs.priceMultiplier
        //otherwise calculate given the current token amounts/price
        setSwapRate("1300 CRV/BNB")
    }

    useEffect(() => {
        getRfsData()
        getCurrentSwapRate()
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
                            <Input placeholder="0" value={tokenOneAmount} onChange={changeAmount} />
                            <Input placeholder="0" value={tokenTwoAmount} disabled={true} />
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
                                    {swapRate}
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
                                        Dynamic/Premium :
                                    </h2>
                                    <p className="font-montserrat font-medium text-sm text-white">
                                        {rfs.priceMultiplier}
                                    </p>
                                </HStack>
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
