"use client"
import React from "react"
import Sidebar from "../components/Sidebar"
import { useState, useEffect } from "react"
import { Input, Popover, Radio, Modal, message } from "antd"
import { ArrowDownOutlined, DownOutlined, SettingOutlined } from "@ant-design/icons"
import { CardData } from "../components/CardData"
import Image from "next/image"
import axios from "axios"
import { HStack, VStack, Button } from "@chakra-ui/react"

const ConfirmSwap = () => {
    const [tokenData, setTokenData] = useState([])
    const [tokenOneAmount, setTokenOneAmount] = useState(null)
    const [tokenTwoAmount, setTokenTwoAmount] = useState(null)
    const [isOpen, setIsOpen] = useState(false)
    const [tokenOne, setTokenOne] = useState(tokenData[0])
    const [tokenTwo, setTokenTwo] = useState(tokenData[1])
    const [changeToken, setChangeToken] = useState(1)
    const [searchTerm, setSearchTerm] = useState("")
    const [isDynamic, setIsDynamic] = useState(true)
    const changeAmount = (e) => {
        setTokenOneAmount(e.target.value)
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
    async function fetchTokenData() {
        try {
            const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")

            // Process the response data
            const tokens = response.data.tokens
            console.log(tokens[0])

            setTokenData(tokens)
            setTokenOne(tokens[0])
            setTokenTwo(tokens[1])
        } catch (error) {
            console.error("Error fetching token data:", error)
        }
    }

    useEffect(() => {
        fetchTokenData()
        console.log("token one ", tokenData ? tokenData[0] : null)
    }, [])
    console.log("token one ", tokenOne ? tokenOne : null)

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
                    {filteredTokens?.map((e, i) => {
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
            <div className="w-full flex h-full justify-center items-center">
                <div className="w-[500px] bg-gray-950 bg-opacity-20 shadow-lg border-opacity-18 border border-gray-600 h-fit rounded-2xl flex flex-col px-10 z-10">
                    <div className="flex justify-between align-middle width-[98%] my-5">
                        <h2 className=" font-montserrat text-gray-400 text-xl  font-bold">Swap</h2>
                        <Popover title="Settings" trigger="click" placement="bottomRight">
                            <SettingOutlined className="text-[#51586f] font-bold transition duration-300 hover:cursor-pointer hover:rotate-90 hover:text-white" />
                        </Popover>
                    </div>

                    <div className="relative mb-3">
                        <Input placeholder="0" value={tokenOneAmount} onChange={changeAmount} />
                        <Input placeholder="0" value={tokenTwoAmount} disabled={true} />
                        <div className="absolute min-w-[80px] h-8 bg-[#3a4157] top-[30px] right-[20px] rounded-full flex justify-start align-middle gap-1 font-bold text-base pr-[8px]">
                            {tokenOne ? (
                                <Image
                                    src={tokenOne?.logoURI}
                                    alt="assetlogoURI"
                                    height={10}
                                    width={30}
                                    className="rounded-full mr-2 p-1"
                                />
                            ) : null}
                            {tokenOne ? (
                                <p className="text-gray-400  mt-1">{tokenOne?.symbol}</p>
                            ) : null}
                        </div>
                        <div
                            onClick={() => openModal(2)}
                            className="hover:cursor-pointer  absolute min-w-[80px] h-8 bg-[#3a4157] top-[135px] right-[20px] rounded-full flex justify-start align-middle gap-1 font-bold text-base pr-[8px]"
                        >
                            {tokenTwo ? (
                                <Image
                                    src={tokenTwo?.logoURI}
                                    alt="assetlogoURI"
                                    height={10}
                                    width={30}
                                    className="rounded-full mr-1 p-1"
                                />
                            ) : null}
                            {tokenTwo ? (
                                <p className="text-gray-400  mt-1">{tokenTwo?.symbol}</p>
                            ) : null}
                            <DownOutlined className="text-gray-300 font-bold mt-2" />
                        </div>

                        <HStack className=" mb-3">
                            <h2 className=" font-montserrat font-bold text-lg text-gray-400 te">
                                Current swap price :
                            </h2>
                            <p className="font-montserrat font-medium text-sm text-gray-400">
                                130 CRV/BNB{" "}
                            </p>
                        </HStack>
                        <HStack className=" mb-3">
                            <h2 className=" font-montserrat font-bold text-lg text-gray-400">
                                Sender Address :
                            </h2>
                            <p className="font-montserrat font-medium text-sm text-gray-400">
                                0x123......
                            </p>
                        </HStack>
                        {isDynamic ? (
                            <HStack className=" mb-3">
                                <h2 className=" font-montserrat font-bold text-lg text-gray-400">
                                    Dynamic/Premium :
                                </h2>
                                <p className="font-montserrat font-medium text-sm text-gray-400">
                                    0x123......
                                </p>
                            </HStack>
                        ) : null}
                        <div className="w-full flex justify-center mb-5">
                            <Button className="bg-blue-gradient rounded-xl h-fit w-fit py-2  px-16">
                                Swap
                            </Button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default ConfirmSwap
