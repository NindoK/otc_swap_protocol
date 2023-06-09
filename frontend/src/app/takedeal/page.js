"use client"
import Sidebar from "@components/Sidebar"
import TakeDealCard from "@components/TakeDealCard"
import React, { useState, useEffect } from "react"
import { BigNumber, ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import OtcOptionAbi from "@constants/abis/OtcOptionAbi"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import { RepeatIcon } from "@chakra-ui/icons"

const page = () => {
    const [searchTerm, setSearchTerm] = useState("")
    const [cardData, setCardData] = useState([])

    const filteredCards = cardData.filter((card) => {
        return card.id.toString().includes(searchTerm)
    })

    const tokenAddressToSymbol = {
        "0xB4D7B61B19aa9b2F3f03B2892De317CB95Dcef92": "mWETH",
        "0x56c575fBf5Bc242b6086326b89f839063acd7fCb": "mDAI",
        "0xf69b85646d86db95023A6C2df4327251e35F2C84": "mLINK",
    }

    const dealStateMap = {
        0: "Open",
        1: "Taken",
        2: "Removed",
        3: "Settled",
    }

    const convertIntToFloatString = (n, decimals) => {
        // n is a BigNumber
        let divisor = BigNumber.from(10).pow(decimals)

        let quotient = n.div(divisor)
        let remainder = n.mod(divisor)

        let quotientStr = quotient.toString()
        let remainderStr = remainder.toString()

        let res = quotientStr + "." + remainderStr
        res = res.replace(/(\.[0-9]*[1-9])0+$/g, "$1")
        res = res.replace(/\.0*$/, ".0")
        return res
    }

    useEffect(() => {
        handleRefresh()
    }, [])

    const handleRefresh = async (e) => {
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const chainId = (await provider.getNetwork()).chainId
        console.log(chainId)
        const otcOption = new ethers.Contract(
            networkMapping[chainId].OtcOption,
            OtcOptionAbi,
            signer
        )
        console.log(otcOption)

        const dealCounter = (await otcOption.dealCounter()).toNumber()
        console.log(dealCounter)

        let deals = []
        for (let i = dealCounter - 1; i > 0; i--) {
            try {
                const deal = await otcOption.getDeal(i)
                console.log(deal)
                const dealInfo = {
                    id: deal["id"].toString(),
                    isCall: deal["isCall"],
                    isMakerBuyer: deal["isMakerBuyer"],
                    maker: deal["maker"],
                    maturity: deal["maturity"].toString(),
                    amount: deal.amount,
                    premium: deal["premium"],
                    // quoteAmount: deal["quoteAmount"],
                    quoteToken: deal["quoteToken"],
                    status: deal["status"],
                    strike: deal["strike"],
                    taker: deal["taker"],
                    underlyingToken: deal["underlyingToken"],
                }
                const [ulyTokenDec, quoteTokenDec, priceFeedDec] = await otcOption.getDecimals(
                    dealInfo.underlyingToken,
                    dealInfo.quoteToken
                )
                console.log(ulyTokenDec, quoteTokenDec, priceFeedDec)
                const dealInfoConverted = {
                    id: dealInfo.id,
                    underlyingToken: tokenAddressToSymbol[dealInfo.underlyingToken],
                    quoteToken: tokenAddressToSymbol[dealInfo.quoteToken],
                    strike: convertIntToFloatString(dealInfo.strike, priceFeedDec),
                    maturity: dealInfo.maturity,
                    optionType: dealInfo.isCall ? "Call" : "Put",
                    amount: convertIntToFloatString(dealInfo.amount, ulyTokenDec),
                    premium: convertIntToFloatString(dealInfo.premium, quoteTokenDec),
                    status: dealStateMap[dealInfo.status],
                    buyer: dealInfo.isMakerBuyer ? dealInfo.maker : dealInfo.taker,
                    seller: dealInfo.isMakerBuyer ? dealInfo.taker : dealInfo.maker,
                }
                console.log(dealInfoConverted)
                deals.push(dealInfoConverted)
            } catch (ex) {
                console.error(ex)
                break
            }
        }
        console.log(deals)
        setCardData(deals)
    }

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
               <ConnectButton/>
               </div>
                <div className=" w-full flex justify-start">
                    <input
                        type="text"
                        placeholder="Search by ID"
                        className="p-2 border border-gray-300 bg-gray-black rounded mt-10 ml-40 text-gray-400"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                    <RepeatIcon
                        className="mt-10 ml-5 hover:cursor-pointer"
                        w={8}
                        h={8}
                        color="white"
                        onClick={handleRefresh}
                    />
                </div>

                <ul className="mt-6 ml-40 flex flex-row gap-5 flex-wrap">
                    {filteredCards.map((val, key) => {
                        return (
                            <li>
                                <TakeDealCard
                                    key={key}
                                    id={val.id}
                                    underlyingtoken={val.underlyingToken}
                                    quotetoken={val.quoteToken}
                                    strike={val.strike}
                                    maturity={val.maturity}
                                    optionType={val.optionType}
                                    amount={val.amount}
                                    premium={val.premium}
                                    status={val.status}
                                    buyer={val.buyer}
                                    seller={val.seller}
                                />
                            </li>
                        )
                    })}
                </ul>
            </div>
        </div>
    )
}

export default page
