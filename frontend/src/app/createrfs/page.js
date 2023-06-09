"use client"

import React, { useEffect, useState, useRef } from "react"
import Navbar from "@components/Navbar"
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
import coinGeckoCachedResponse from "@constants/coinGeckoCachedResponse"

const CreateRfs = () => {
    const [tokenData, setTokenData] = useState([])
    const [interactionType, setInteractionType] = useState("")
    const [rfsType, setRfsType] = useState("")
    const [priceMultiplier, setPriceMultiplier] = useState(0)
    const [tokenOffered, setTokenOffered] = useState("") //address
    const [tokensAccepted, setTokensAccepted] = useState([]) //address[]
    const [amount0Offered, setAmount0Offered] = useState(0) //uint256
    const [amount1Requested, setAmount1Requested] = useState(0) //uint256
    const [deadline, setDeadline] = useState(0) //unix timestamp
    const [usdPrice, setUsdPrice] = useState(0) //uint256
    const deadlineInputRef = useRef();

    const [chainId, setChainId] = useState(null)
    async function fetchTokenData() {
        try {
            const provider = new ethers.providers.Web3Provider(window.ethereum)
            const chainId = (await provider.getNetwork()).chainId
            setChainId(chainId)

            let tokens
            if (coinGeckoCachedResponse) {
                tokens = coinGeckoCachedResponse.tokens
            } else {
                const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")

                // Process the response data
                tokens = response.data.tokens
            }
            setTokenData(tokens)
        } catch (error) {
            console.error("Error fetching token data:", error)
        }
    }

    const handleDeadlineChange = (e) => {
      setDeadline(e.target.value);
      // Call the blur method to lose focus
      deadlineInputRef.current.blur();
    };
    const resetRfsTypeDependentDate = (e) => {
      setTokensAccepted([]);
      setPriceMultiplier(0);
      setUsdPrice(0);
      setAmount1Requested(0);
    };

    const handleSubmit = async (e) => {
        e.preventDefault()
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()
        const otcNexus = new ethers.Contract(networkMapping[chainId].OtcNexus, OtcNexusAbi, signer)
        const interactionTypeSelected = interactionType === "Deposited" ? 0 : 1
        const deadlineInUnixtimestamp = new Date(deadline).getTime() / 1000

        let tx
        try {
            if (rfsType === "Dynamic") {
                tx = await otcNexus.createDynamicRfs(
                    tokenOffered,
                    tokensAccepted,
                    amount0Offered,
                    priceMultiplier,
                    deadlineInUnixtimestamp,
                    interactionTypeSelected
                )
            } else if (rfsType === "Fixed_Usd") {
                tx = await otcNexus.createFixedRfs(
                    tokenOffered,
                    tokensAccepted,
                    amount0Offered,
                    0,
                    usdPrice,
                    deadlineInUnixtimestamp,
                    interactionTypeSelected
                )
            } else if (rfsType === "Fixed_Amount") {
                tx = await otcNexus.createFixedRfs(
                    tokenOffered,
                    tokensAccepted,
                    amount0Offered,
                    parseFloat(amount1Requested),
                    0,
                    deadlineInUnixtimestamp,
                    interactionTypeSelected
                )
            }
            const receipt = await tx.wait()
            console.log(
                "The transaction have been successfully completed. You can fine the trnsaction with the current txn hash: ",
                receipt.transactionHash
            )

            console.log(
                "You paid a total of: ",
                ethers.utils.formatEther(
                    receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice),
                    "ether"
                )
            )
        } catch (error) {
            console.log(error.stack)
        }
    }

    useEffect(() => {
        let now = new Date();
        now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
        const minDateTime = now.toISOString().slice(0,16);
        deadlineInputRef.current.min = minDateTime;
        fetchTokenData()
    }, [])

    const isFormValid = () => {
        return (
         deadline !== '' &&
          tokenOffered !== '' &&
          amount0Offered !== '' &&
          interactionType !== '' &&
          rfsType !== '' &&
          ((rfsType === 'Dynamic' && tokensAccepted.length>0 && priceMultiplier!== '') ||
            (rfsType === 'Fixed_Usd' && tokensAccepted.length>0 && usdPrice>0) ||
            (rfsType === 'Fixed_Amount' && tokensAccepted.length>0 && amount1Requested>0))
        );
      };

    return (
        <>
            <div className={`${styles.paddingX} ${styles.flexCenter} bg-black`}>
                <div className={`${styles.boxWidth}`}>
                    <Navbar />
                </div>
                <div className="h-fit w-60 text-center -mr-50 rounded-xl z-30">
                    <ConnectButton showBalance={false} />
                </div>
            </div>
            <div className="flex min-h-screen w-full bg-black">
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
                                        ref={deadlineInputRef}
                                        value={deadline}
                                        onChange={handleDeadlineChange}
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

                                <FormControl isRequired>
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
                                    <RadioGroup onChange={(value) => {setRfsType(value); resetRfsTypeDependentDate();}} value={rfsType}>
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
                                                    setTokensAccepted={setTokensAccepted}
                                                />
                                            </Box>
                                        </FormControl>
                                        <FormControl isRequired>
                                            <FormLabel>Discount/Premium</FormLabel>
                                            <Box p={4}>
                                                <PercentageSlider
                                                    value={priceMultiplier}
                                                    setPriceMultiplier={setPriceMultiplier}
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
                                                onChange={(e) =>
                                                    setTokensAccepted([e.target.value])
                                                }
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
                                                min={0}
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

                                <div className="flex w-full justify-center">
                                    <Button
                                        isDisabled={!isFormValid()}
                                        className="bg-blue-gradient rounded-xl py-2 px-4 top-5"
                                        type="submit"
                                    >
                                        Submit
                                    </Button>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </>
    )
}

export default CreateRfs
