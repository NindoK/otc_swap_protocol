"use client"

import React, { useState } from "react"
import Navbar from "@components/Navbar"
import styles from "../style"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import {
    Button,
    FormControl,
    FormErrorMessage,
    FormHelperText,
    FormLabel,
    Input,
    useNumberInput,
    NumberInput,
    NumberInputField,
    Select,
} from "@chakra-ui/react"
import { useToast } from "@chakra-ui/react"
import { BigNumber, ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import OtcOptionAbi from "@constants/abis/OtcOptionAbi"
import Sidebar from "@components/Sidebar"

const CreateDeal = () => {
    const toast = useToast()
    const [createDealFormData, setCreateDealFormData] = useState({
        underlyingToken: "",
        quoteToken: "",
        strike: "",
        maturity: new Date(),
        optionType: "",
        amount: "",
        premium: "",
        side: "",
    })

    const tokenData = [
        {
            symbol: "mWETH",
            address: "0xB4D7B61B19aa9b2F3f03B2892De317CB95Dcef92",
        },
        {
            symbol: "mDAI",
            address: "0x56c575fBf5Bc242b6086326b89f839063acd7fCb",
        },
        {
            symbol: "mLINK",
            address: "0xf69b85646d86db95023A6C2df4327251e35F2C84",
        },
    ]
    // const tokenData = networkMapping[chainId]["mockTokens"]

    const handleUTInputChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            underlyingToken: e.target.value,
        }))
    }
    const handleQTInputChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            quoteToken: e.target.value,
        }))
    }
    const handleStrikeChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            strike: e.target.value,
        }))
    }
    const handleMaturityChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            maturity: e.target.value,
        }))
    }
    const handleOptionChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            optionType: e.target.value,
        }))
    }
    const handleAmountChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            amount: e.target.value,
        }))
    }
    const handlePremiumChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            premium: e.target.value,
        }))
    }
    const handleSideChange = (e) => {
        setCreateDealFormData((prevData) => ({
            ...prevData,
            side: e.target.value,
        }))
    }

    const handleSubmit = async (event) => {
        event.preventDefault()
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const chainId = (await provider.getNetwork()).chainId
        const otcOption = new ethers.Contract(
            networkMapping[chainId].OtcOption,
            OtcOptionAbi,
            signer
        )
        // console.log(otcOption)

        try {
            const info = createDealFormData

            const [ulyTokenDec, quoteTokenDec, priceFeedDec] = await otcOption.getDecimals(
                info["underlyingToken"],
                info["quoteToken"]
            )
            const inputInfo = {
                ulyToken: info["underlyingToken"],
                quoteToken: info["quoteToken"],
                strike: (parseFloat(info["strike"]) * 10 ** priceFeedDec).toString(),
                maturity: new Date(info["maturity"]).getTime() / 1000,
                isCall: info["optionType"].toLowerCase() === "call",
                amount: (parseFloat(info["amount"]) * 10 ** ulyTokenDec).toString(),
                premium: (parseFloat(info["premium"]) * 10 ** quoteTokenDec).toString(),
                isMakerBuyer: info["side"].toLowerCase() === "buy",
            }
            console.log(inputInfo)

            const tx = await otcOption.createDeal(
                inputInfo["ulyToken"],
                inputInfo["quoteToken"],
                inputInfo["strike"],
                inputInfo["maturity"],
                inputInfo["isCall"],
                inputInfo["amount"],
                inputInfo["premium"],
                inputInfo["isMakerBuyer"]
            )
            const receipt = await tx.wait()
            console.log(receipt)
            if (receipt)
                toast({
                    title: "Deal created!",
                    status: "success",
                    duration: 9000,
                    isClosable: true,
                })
        } catch (error) {
            console.error(error)
            toast({
                title: "There was some error!",
                status: "error",
                duration: 9000,
                isClosable: true,
            })
        }
    }

    return (
        
            <div className="flex min-h-screen h-fit w-full bg-black">
                {/* gradient start */}
                <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
                <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
                <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />

                <Sidebar/>
                <div className="w-full flex flex-col ">
            <div className="w-full flex justify-end py-3 pr-2 z-10">
               <ConnectButton/></div>
               <div className="flex justify-center  w-full">
               <form
                   onSubmit={handleSubmit}
                   className="  text-gray-400 font-montserrat h-fit w-fit lg:p-10 p-6  bg-white bg-opacity-5 shadow-md  backdrop-blur rounded-xl border border-gray-400 border-opacity-18 "
               >
                   <h2 className="text-center font-bold font-montserrat text-2xl">
                       Create a Deal
                   </h2>
                   <div className="lg:flex gap-14 ">
                       <FormControl isRequired className="flex flex-col lg:my-5 my-3">
                           <FormLabel className=" font-bold">Underlying Token</FormLabel>
                           <Select
                               value={createDealFormData.underlyingToken}
                               onChange={handleUTInputChange}
                               placeholder="-None-"
                           >
                               {tokenData.map((token) => (
                                   <option key={token.symbol} value={token.address} className=" bg-gray-black text-gray-800">
                                       <span>{token.symbol}</span>
                                   </option>
                               ))}
                           </Select>
                       </FormControl>

                       <FormControl isRequired className="flex flex-col my-5">
                           <FormLabel className=" font-bold">Quote Token</FormLabel>
                           <Select
                               value={createDealFormData.quoteToken}
                               onChange={handleQTInputChange}
                               placeholder="-None-"
                           >
                               {tokenData.map((token) => (
                                   <option key={token.symbol} value={token.address} className=" bg-gray-black text-gray-800">
                                       <span>{token.symbol}</span>
                                   </option>
                               ))}
                           </Select>
                       </FormControl>
                   </div>

                   <div className="lg:flex gap-14">
                       <FormControl isRequired className="flex flex-col my-5">
                           <FormLabel className=" font-bold">Strike</FormLabel>
                           <Input
                               type="number"
                               placeholder="Strike"
                               value={createDealFormData.strike}
                               onChange={handleStrikeChange}
                           />
                       </FormControl>

                       <FormControl isRequired className="flex flex-col my-5">
                           <FormLabel className=" font-bold">Maturity</FormLabel>
                           <Input
                               name="maturity"
                               placeholder="Select Date and Time"
                               size="md"
                               type="datetime-local"
                               value={createDealFormData.maturity}
                               onChange={handleMaturityChange}
                           />
                       </FormControl>
                   </div>

                   <div className="lg:flex gap-14">
                       <FormControl isRequired className="flex flex-col my-5">
                           <FormLabel className=" font-bold">Option Type</FormLabel>
                           <Select
                               placeholder="-None-"
                               name="optionType"
                               value={createDealFormData.optionType}
                               onChange={handleOptionChange}
                           >
                               <option className=" text-gray-800">Call</option>
                               <option className=" text-gray-800">Put</option>
                           </Select>
                       </FormControl>

                       <FormControl isRequired className="flex flex-col my-5">
                           <FormLabel className=" font-bold">Amount</FormLabel>
                           <Input
                               type="number"
                               placeholder="Amount"
                               value={createDealFormData.amount}
                               onChange={handleAmountChange}
                           />
                       </FormControl>
                   </div>

                   <div className="lg:flex gap-14">
                       <FormControl isRequired className="flex flex-col my-5">
                           <FormLabel className=" font-bold">Side</FormLabel>
                           <Select
                               placeholder="-None-"
                               name="side"
                               value={createDealFormData.side}
                               onChange={handleSideChange}
                           >
                               <option className=" text-gray-800">Buy</option>
                               <option className=" text-gray-800">Sell</option>
                           </Select>
                       </FormControl>

                       <FormControl isRequired className="flex flex-col my-5">
                           <FormLabel className=" font-bold">Premium</FormLabel>
                           <Input
                               type="number"
                               placeholder="Premium"
                               value={createDealFormData.premium}
                               onChange={handlePremiumChange}
                           />
                       </FormControl>
                   </div>

                   <div className="w-full flex justify-center ">
                       <Button
                           className="bg-blue-gradient rounded-xl h-fit w-fit py-2  px-4"
                           type="submit"
                       >
                           Submit
                       </Button>
                   </div>
               </form>
           </div>
            
            </div>

                
            </div>
       
    )
}

export default CreateDeal
