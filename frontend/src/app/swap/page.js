"use client"
import React from "react"
import Sidebar from "@components/Sidebar"
import CardComponent from "@components/CardComponent"
import { CardData } from "@components/CardData"
import dynamic from "next/dynamic"
import Navbar from "@components/Navbar"
import { ConnectButton } from "@rainbow-me/rainbowkit"

const swap = () => {
    const retrieveAvailableRfs = async () => {
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const chainId = (await provider.getNetwork()).chainId
        const otcNexus = new ethers.Contract(networkMapping[chainId].OtcNexus, OtcNexusAbi, signer)

        // Retrieve all past NewRFS events from the contract.
        contract
            .getPastEvents("NewRFS", {
                fromBlock: 0, // Starting block
                toBlock: "latest", // Ending block
            })
            .then((events) => {
                // For each NewRFS event, fetch the corresponding RFS and update the front-end.
                events.forEach((event) => {
                    const rfsId = event.returnValues.id

                    contract.methods
                        .idToRfs(rfsId)
                        .call()
                        .then((rfs) => {
                            console.log("Received RFS:", rfs)
                            // Now you can update your front-end to include this RFS.
                        })
                        .catch(console.error)
                })
            })
            .catch(console.error)
    }

    return (
        <div className="flex h-fit w-full bg-black">
            {/* gradient start */}
            <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
            <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
            <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />
            {/* gradient end */}
            <Sidebar />

            <ul className="mt-36 ml-40">
                {CardData.map((val, key) => {
                    return (
                        <li>
                            <CardComponent
                                key={key}
                                condition={val.condition}
                                label={val.label}
                                icon={val.icon}
                                assets={val.assets}
                                discount={val.Discount}
                                price={val.Price}
                                ttokens={val.TTokens}
                                tvalue={val.TValue}
                                title={val.title}
                            />
                        </li>
                    )
                })}
            </ul>
        </div>
    )
}
export default dynamic(() => Promise.resolve(swap), { ssr: false })
