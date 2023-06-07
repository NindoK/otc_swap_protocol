"use client"

import React, { useEffect, useState } from "react"
import Navbar from "../components/Navbar"
import styles from "../style"
import axios from "axios"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import {
    Avatar,
    Box,
    Button,
    Flex,
    FormControl,
    FormLabel,
    Input,
    Image,
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
import PercentageSlider from "@components/PercentageSlider"
import MultipleTags from "@components/MultipleTags"
import { ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import OtcNexusAbi from "@constants/abis/OtcNexusAbi"

const CreateRfs = () => {
    const [tokenData, setTokenData] = useState([])
    const [interactionType, setInteractionType] = useState("0")
    const [rfsType, setRfsType] = useState("")
    const [priceMultiplier, setPriceMultiplier] = useState(0)
    const [tokenOffered, setTokenOffered] = useState("") //address
    const [tokensAccepted, setTokensAccepted] = useState("") //address[]
    const [amount0Offered, setAmount0Offered] = useState(0) //uint256
    const [amount1Requested, setAmount1Requested] = useState(0) //uint256
    const [deadline, setDeadline] = useState(0) //unix timestamp
    const [usdPrice, setUsdPrice] = useState(0) //uint256

    async function fetchTokenData() {
        try {
            console.log("Fetching token data...")
            const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")
            console.log(response)

            // Process the response data
            const tokens = response.data.tokens
            console.log(tokens)

            setTokenData(tokens)
        } catch (error) {
            console.error("Error fetching token data:", error)
        }
    }

    const handleSubmit = async (e) => {
        e.preventDefault()
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const chainId = (await provider.getNetwork()).chainId
        const otcNexus = new ethers.Contract(networkMapping[chainId].OtcNexus, OtcNexusAbi, signer)
        console.log(otcNexus)
        const interactionTypeSelected = interactionType === "Deposited" ? 0 : 1
        const deadlineInUnixtimestamp = new Date(deadline).getTime() / 1000
        // let tokensAcceptedLowerCased = tokensAccepted.map((token) => token.toLowerCase())
        // tokensAcceptedLowerCased.push("0XC02AAA39B223FE8D0A0E5C4F27EAD9083C756CC2".toLowerCase())
        let tx
        const rfsIdCounter = await otcNexus.rfsIdCounter()
        console.log("RFS ID Counter: ", rfsIdCounter.toString())
        const rfs = await otcNexus.getRfs((rfsIdCounter - 1).toString())
        console.log("RFS: ", rfs)
        // console.log(
        //     tokenOffered.toLowerCase(),
        //     tokensAcceptedLowerCased,
        //     amount0Offered,
        //     priceMultiplier,
        //     deadlineInUnixtimestamp,
        //     interactionTypeSelected
        // )

        console.log(
            tokenOffered.toLowerCase(),
            [tokensAccepted.toLowerCase()],
            amount0Offered,
            parseFloat(amount1Requested),
            0,
            deadlineInUnixtimestamp,
            interactionTypeSelected
        )
        try {
            if (rfsType === "Dynamic") {
                tx = await otcNexus.createDynamicRfs(
                    "0x93567d6B6553bDe2b652FB7F197a229b93813D3f".toLowerCase(),
                    ["0xdAC17F958D2ee523a2206206994597C13D831ec7".toLowerCase()],
                    40,
                    90,
                    1686168300,
                    0
                )
            } else if (rfsType === "Fixed_Usd") {
                tx = await otcNexus.createFixedRfs(
                    tokenOffered,
                    tokensAccepted,
                    amount0Offered,
                    0,
                    usdPrice,
                    deadline,
                    interactionTypeSelected
                )
            } else if (rfsType === "Fixed_Amount") {
                //TODO TO BE ADJUSTED
                tx = await otcNexus.createFixedRfs(
                    tokenOffered.toLowerCase(),
                    [tokensAccepted.toLowerCase()],
                    amount0Offered,
                    parseFloat(amount1Requested),
                    0,
                    deadlineInUnixtimestamp,
                    interactionTypeSelected
                )
            }
            const receipt = await tx.wait()
        } catch (error) {
            console.log(error.stack)
        }
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
                                        value={deadline}
                                        onChange={(e) => setDeadline(e.target.value)}
                                        placeholder="Select Date and Time"
                                        size="md"
                                        type="datetime-local"
                                    />
                                </FormControl>

                                <FormControl isRequired className="flex flex-col my-5">
                                    <FormLabel className=" font-bold">Token Offered</FormLabel>
                                    <Select
                                        value={tokenOffered}
                                        onChange={(e) => setTokenOffered(e.target.value)}
                                        placeholder="-None-"
                                    >
                                        {tokenData.map((token) => (
                                            <option
                                                key={`${token.name}-${token.symbol}`}
                                                value={token.address}
                                            >
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
                                    <NumberInput
                                        value={amount0Offered}
                                        onChange={(e) => {
                                            const value = parseInt(e, 10)
                                            if (!isNaN(value)) {
                                                setAmount0Offered(value)
                                            }
                                        }}
                                        defaultValue={15}
                                        precision={4}
                                        step={0.2}
                                    >
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
                                                <MultipleTags
                                                    tokensAccepted={tokensAccepted}
                                                    setTokensAccepted={setTokensAccepted}
                                                />
                                            </Box>
                                        </FormControl>
                                        <FormControl isRequired>
                                            <FormLabel>Discount/Premium</FormLabel>
                                            <Box p={4}>
                                                <PercentageSlider
                                                    value={priceMultiplier}
                                                    onChange={setPriceMultiplier}
                                                />
                                            </Box>
                                        </FormControl>
                                    </div>
                                )}
                                {rfsType === "Fixed_Usd" && (
                                    <div>
                                        <FormControl isRequired>
                                            <FormLabel>Tokens accepted</FormLabel>
                                            <Box p={4}>
                                                <MultipleTags
                                                    tokensAccepted={tokensAccepted}
                                                    setTokensAccepted={setTokensAccepted}
                                                />
                                            </Box>{" "}
                                        </FormControl>
                                        <FormControl isRequired>
                                            <FormLabel>USD price</FormLabel>
                                            <NumberInput
                                                value={usdPrice}
                                                onChange={(e) => {
                                                    const value = parseInt(e, 10)
                                                    if (!isNaN(value)) {
                                                        setUsdPrice(value)
                                                    }
                                                }}
                                                defaultValue={15}
                                                precision={4}
                                                step={0.2}
                                            >
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
                                            <Select
                                                value={tokensAccepted}
                                                onChange={(e) => setTokensAccepted(e.target.value)}
                                                placeholder="-None-"
                                            >
                                                {tokenData.slice(0, 20).map((token) => (
                                                    <option
                                                        key={`${token.name}-${token.symbol}`}
                                                        value={token.address}
                                                    >
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
                                            <FormLabel>Amount Requested</FormLabel>
                                            <NumberInput
                                                value={amount1Requested}
                                                onChange={setAmount1Requested}
                                                defaultValue={15}
                                                precision={4}
                                                step={0.2}
                                            >
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
