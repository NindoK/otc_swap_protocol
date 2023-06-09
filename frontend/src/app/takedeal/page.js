"use client"
// import { CardData } from "@components/CardData"
import Sidebar from "@components/Sidebar"
import TakeDealCard from "@components/TakeDealCard"
import React, { useState } from "react"
import { BigNumber, ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import OtcOptionAbi from "@constants/abis/OtcOptionAbi"
import { ConnectButton } from "@rainbow-me/rainbowkit"

const page = () => {
    const [searchTerm, setSearchTerm] = useState("")
    const [cardData, setCardData] = useState([])

    
    const filteredCards = cardData.filter((card) => {
        return card.id.toString().includes(searchTerm)
    })

    const handleRefresh = async (e) => {
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const chainId = (await provider.getNetwork()).chainId
        const otcOption = new ethers.Contract(
            networkMapping[chainId].OtcOption,
            OtcOptionAbi,
            signer
        )
        console.log(otcOption)

        const dealCounter = (await otcOption.dealCounter()).toNumber()
        console.log(dealCounter)

        let deals = []
        for (let i = 1; i < dealCounter; i++) {
            try {
                const deal = await otcOption.getDeal(i)
                const dealInfo = {
                    id: deal["id"].toString(),
                    isCall: deal["isCall"],
                    isMakerBuyer: deal["isMakerBuyer"],
                    maker: deal["maker"],
                    maturity: deal["maturity"].toString(),
                    premium: deal["premium"].toString(),
                    quoteAmount: deal["quoteAmount"].toString(),
                    quoteToken: deal["quoteToken"],
                    status: deal["status"],
                    strike: deal["strike"].toString(),
                    taker: deal["taker"],
                    underlyingToken: deal["underlyingToken"],
                }
                deals.push(dealInfo)
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
                    <button onClick={handleRefresh}>Refresh</button>
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
                                    // optioncall={val.optioncall}
                                    amount={val.amount}
                                    premium={val.premium}
                                    status={val.status}
                                    // buyer={val.buyer}
                                    // seller={val.seller}
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
