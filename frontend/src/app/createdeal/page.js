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
const CreateDeal = () => {
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

    const handleSubmit = (event) => {
        event.preventDefault()
        console.log(JSON.stringify(createDealFormData))
    }

    return (
        <React.Fragment>
        
            <div className={`${styles.paddingX} ${styles.flexCenter} bg-black`}>
                <div className={`${styles.boxWidth}`}>
                    <Navbar />
                </div>
              
                    <ConnectButton showBalance={false} />
               
            </div>
            <div className="flex lg:h-screen w-full bg-black">
                {/* gradient start */}
                <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
                <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
                <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />

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
                                <Input
                                    name="underlyingToken"
                                    variant="flushed"
                                    placeholder="Address"
                                    value={createDealFormData.underlyingToken}
                                    onChange={handleUTInputChange}
                                />
                            </FormControl>

                            <FormControl isRequired className="flex flex-col my-5">
                                <FormLabel className=" font-bold">Quote Token</FormLabel>
                                <Input
                                    name="quoteToken"
                                    variant="flushed"
                                    placeholder="Address"
                                    value={createDealFormData.quoteToken}
                                    onChange={handleQTInputChange}
                                />
                            </FormControl>
                        </div>

                        <div className="lg:flex gap-14">
                            <FormControl isRequired className="flex flex-col my-5">
                                <FormLabel className=" font-bold">Strike</FormLabel>
                                <Input
                                    type="number"
                                    placeholder="strike amount"
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
                                    type="date"
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
                                    <option>Call</option>
                                    <option>Put</option>
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
                                    <option>Buy</option>
                                    <option>Sell</option>
                                </Select>
                            </FormControl>

                            <FormControl isRequired className="flex flex-col my-5">
                                <FormLabel className=" font-bold">Premium</FormLabel>
                                <Input
                                    type="number"
                                    placeholder="premium"
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
        </React.Fragment>
    )
}

export default CreateDeal
