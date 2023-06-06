"use client"

import React, { useEffect, useState } from "react"
import Navbar from "../../../components/Navbar"
import styles from "../style"
import axios from "axios"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import {
    Avatar,
    Box,
    Button,
    FormControl,
    FormLabel,
    Image,
    Input,
    NumberDecrementStepper,
    NumberIncrementStepper,
    NumberInput,
    NumberInputField,
    NumberInputStepper,
    Radio,
    RadioGroup,
    Select,
    Stack,
} from "@chakra-ui/react"
import PercentageSlider from "../../../components/PercentageSlider"
import MultipleTags from "../../../components/MultipleTags"

import PercentageSlider from "../components/PercentageSlider"
import MultipleTags from "../components/MultipleTags"

const CreateRfs = () => {
    const [tokenData, setTokenData] = useState([])
    const [interactionType, setInteractionType] = useState("0")
    const [rfsType, setRfsType] = useState("")

    async function fetchTokenData() {
        try {
            const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")

            // Process the response data
            const tokens = response.data.tickers
            console.log(tokens)

            setTokenData(tokens)
        } catch (error) {
            console.error("Error fetching token data:", error)
        }
    }

    const handleSubmit = async (e) => {
        e.preventDefault()
    }
    useEffect(() => {
        fetchTokenData()
    }, [])

    return (
        <>
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
                    <form
                        onSubmit={handleSubmit}
                        className="  text-gray-400 font-montserrat h-fit w-fit lg:p-10 p-6  bg-white bg-opacity-5 shadow-md  backdrop-blur rounded-xl border border-gray-400 border-opacity-18 "
                    >
                        <h2 className="text-center font-bold font-montserrat text-2xl">
                            Create RFS
                        </h2>
                        <div className=" gap-14 ">
                            <div className="w-full justify-center ">
                                <FormControl isRequired className="flex flex-col my-5">
                                    <FormLabel className=" font-bold">Datetime deadline</FormLabel>
                                    <Input
                                        placeholder="Select Date and Time"
                                        size="md"
                                        type="datetime-local"
                                    />
                                </FormControl>

                                <FormControl isRequired className="flex flex-col my-5">
                                    <FormLabel className=" font-bold">Token Offered</FormLabel>
                                    <Select placeholder="-None-">
                                        {tokenData.map((token) => (
                                            <option key={token.id}>
                                                <Image
                                                    borderRadius="full"
                                                    boxSize="40px"
                                                    src={token.logoURI}
                                                    alt="token image"
                                                />
                                                <span>{token.symbol}</span>
                                            </option>
                                        ))}
                                    </Select>
                                </FormControl>

                                <FormControl isRequired>
                                    <FormLabel>Amount Offered</FormLabel>
                                    <NumberInput defaultValue={15} precision={4} step={0.2}>
                                        <NumberInputField />
                                        <NumberInputStepper>
                                            <NumberIncrementStepper />
                                            <NumberDecrementStepper />
                                        </NumberInputStepper>
                                    </NumberInput>
                                </FormControl>

                                <FormControl>
                                    <RadioGroup
                                        onChange={setInteractionType}
                                        value={interactionType}
                                    >
                                        <Stack direction="row">
                                            <Radio value="Deposited">Deposited</Radio>
                                            <Radio value="Approved">Approved</Radio>
                                        </Stack>
                                    </RadioGroup>
                                </FormControl>

                                <FormControl>
                                    <RadioGroup onChange={setRfsType} value={rfsType}>
                                        <Stack direction="row">
                                            <Radio value="Dynamic">Dynamic</Radio>
                                            <Radio value="Fixed_Usd">Fixed Usd</Radio>
                                            <Radio value="Fixed_Amount">Fixed amount</Radio>
                                        </Stack>
                                    </RadioGroup>
                                </FormControl>
                                {rfsType === "Dynamic" && (
                                    <div>
                                        <FormControl isRequired>
                                            <FormLabel>Tokens accepted</FormLabel>
                                            <Box p={4}>
                                                <MultipleTags />
                                            </Box>
                                        </FormControl>
                                        <FormControl isRequired>
                                            <FormLabel>Discount/Premium</FormLabel>
                                            <Box p={4}>
                                                <PercentageSlider />
                                            </Box>
                                        </FormControl>
                                    </div>
                                )}
                                {rfsType === "Fixed_Usd" && (
                                    <div>
                                        <FormControl isRequired>
                                            <FormLabel>Tokens accepted</FormLabel>
                                            <Box p={4}>
                                                <MultipleTags />
                                            </Box>{" "}
                                        </FormControl>
                                        <FormControl isRequired>
                                            <FormLabel>USD price</FormLabel>
                                            <NumberInput defaultValue={15} precision={4} step={0.2}>
                                                <NumberInputField />
                                                <NumberInputStepper>
                                                    <NumberIncrementStepper />
                                                    <NumberDecrementStepper />
                                                </NumberInputStepper>
                                            </NumberInput>
                                        </FormControl>
                                    </div>
                                )}
                                {rfsType === "Fixed_Amount" && (
                                    <div>
                                        <FormControl isRequired className="flex flex-col">
                                            <FormLabel className=" font-bold">
                                                Token accepted
                                            </FormLabel>
                                            <Select placeholder="-None-">
                                                {tokenData.slice(0, 20).map((token) => (
                                                    <option key={token.coin_id}>
                                                        {token.coin_id}
                                                    </option>
                                                ))}
                                            </Select>
                                        </FormControl>

                                        <FormControl isRequired>
                                            <FormLabel>Amount Requested</FormLabel>
                                            <NumberInput defaultValue={15} precision={4} step={0.2}>
                                                <NumberInputField />
                                                <NumberInputStepper>
                                                    <NumberIncrementStepper />
                                                    <NumberDecrementStepper />
                                                </NumberInputStepper>
                                            </NumberInput>
                                        </FormControl>
                                    </div>
                                )}

                                <Button
                                    className="bg-blue-gradient rounded-xl py-2 px-4 top-5"
                                    type="submit"
                                >
                                    Submit
                                </Button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </>
    )
}

export default CreateRfs
