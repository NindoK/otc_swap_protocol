"use client"

import React, { useState } from "react"
import Navbar from "../components/Navbar"
import styles from "../style"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import {
    Button,
    FormControl,
    FormErrorMessage,
    FormHelperText,
    FormLabel,
    HStack,
    Input,
    NumberDecrementStepper,
    NumberIncrementStepper,
    NumberInput,
    NumberInputField,
    NumberInputStepper,
    Select,
    useNumberInput,
} from "@chakra-ui/react"
const CreateDeal = () => {
    const [utInput, setUTInput] = useState("")
    const [qtInput, setQTInput] = useState("")
    const [strike, setStrike] = useState(0)
    const [maturity, setMaturity] = useState("")
    const [option, setOption] = useState("")
    const [amount, setAmount] = useState(0)
    const [premium, setPremium] = useState(0)
    const [side, setSide] = useState("")
    const handleUTInputChange = (e) => setUTInput(e.target.value)
    const handleQTInputChange = (e) => setQTInput(e.target.value)
    const handleStrikeChange = (e) => setStrike(e.target.value)
    const handleMaturityChange = (e) => setMaturity(e.target.value)
    const handleOptionChange = (e) => setOption(e.target.value)
    const handleAmountChange = (e) => setAmount(e.target.value)
    const handlePremiumChange = (e) => setPremium(e.target.value)
    const handleSideChange = (e) => setSide(e.target.value)
    const isError = { utInput, qtInput } === ""
    return (
        <React.Fragment>
            <div className={`${styles.paddingX} ${styles.flexCenter} bg-black`}>
                <div className={`${styles.boxWidth}`}>
                    <Navbar />
                </div>
                <div className="h-fit w-60 text-center bg-blue-gradient p-3 pl-4 -mr-50 rounded-xl z-30">
                    <ConnectButton showBalance={false} />
                </div>
            </div>
            <div className="flex lg:h-screen w-full bg-black">
                {/* gradient start */}
                <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
                <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
                <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />

                <div className="flex justify-center  w-full">
                <form className="  text-gray-400 font-montserrat h-fit w-fit lg:p-10 p-6  bg-white bg-opacity-5 shadow-md  backdrop-blur rounded-xl border border-gray-400 border-opacity-18 ">
                    <h2 className="text-center font-bold font-montserrat text-2xl">Create a Deal</h2>
                    <div className="lg:flex gap-14 ">
                    <FormControl isRequired isInvalid={isError} className="flex flex-col lg:my-5 my-3">
                        <FormLabel className=" font-bold">Underlying Token</FormLabel>
                        <Input
                            variant="flushed"
                            placeholder="Address"
                            value={utInput}
                            onChange={handleUTInputChange}
                        />
                        {!isError ? (
                            <FormHelperText className="text-gray-500">
                                Enter the Address of the underlying token.
                            </FormHelperText>
                        ) : (
                            <FormErrorMessage className="text-gray-500">Addres is required.</FormErrorMessage>
                        )}
                    </FormControl>

                    <FormControl isRequired isInvalid={isError} className="flex flex-col my-5">
                        <FormLabel className=" font-bold">Quote Token</FormLabel>
                        <Input
                            variant="flushed"
                            placeholder="Address"
                            value={qtInput}
                            onChange={handleQTInputChange}
                        />
                        {!isError ? (
                            <FormHelperText className="text-gray-500">Enter the Address of the quote token.</FormHelperText>
                        ) : (
                            <FormErrorMessage className="text-gray-500">Addres is required.</FormErrorMessage>
                        )}
                    </FormControl>
                    </div>

                    <div className="lg:flex gap-14">
                    <FormControl isRequired isInvalid={isError} className="flex flex-col my-5">
                        <FormLabel className=" font-bold">Strike</FormLabel>
                        <NumberInput value={strike} onChange={handleStrikeChange} precision={3}>
                            <NumberInputField className=" border-t-0 border-x-0 rounded-none focus: border-b-2" />
                        </NumberInput>
                    </FormControl>

                    <FormControl isRequired isInvalid={isError} className="flex flex-col my-5">
                        <FormLabel className=" font-bold">Maturity</FormLabel>
                        <Input
                            placeholder="Select Date and Time"
                            size="md"
                            type="date"
                            value={maturity}
                            onChange={handleMaturityChange}
                        />
                    </FormControl>
                    </div>

                    <div className="lg:flex gap-14">
                    <FormControl isRequired isInvalid={isError} className="flex flex-col my-5">
                        <FormLabel className=" font-bold">Call or Put</FormLabel>
                        <Select placeholder="-None-" value={option} onChange={handleOptionChange}>
                            <option>Call</option>
                            <option>Put</option>
                        </Select>
                    </FormControl>

                    <FormControl isRequired isInvalid={isError} className="flex flex-col my-5">
                        <FormLabel className=" font-bold">Amount</FormLabel>
                        <NumberInput value={amount} onChange={handleAmountChange} precision={4}>
                            <NumberInputField />
                        </NumberInput>
                    </FormControl>
                    </div>


                    <div className="lg:flex gap-14">
                    <FormControl isRequired isInvalid={isError} className="flex flex-col my-5">
                        <FormLabel className=" font-bold">Side</FormLabel>
                        <Select placeholder="-None-" value={side} onChange={handleSideChange}>
                            <option>Buy</option>
                            <option>sELL</option>
                        </Select>
                    </FormControl>
                    
                    <FormControl isRequired isInvalid={isError} className="flex flex-col my-5">
                        <FormLabel className=" font-bold">Premium</FormLabel>
                        <NumberInput value={premium} onChange={handlePremiumChange} precision={4}>
                            <NumberInputField />
                        </NumberInput>
                    </FormControl>
                    </div>

              <div className="w-full flex justify-center ">
              <Button className="bg-blue-gradient rounded-xl h-fit w-fit py-2  px-4" type="submit">
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
