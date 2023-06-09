"use client"
import React, { useState } from "react"
import { ArrowForwardIcon, WarningIcon } from "@chakra-ui/icons"
import {
    Modal,
    ModalBody,
    ModalCloseButton,
    ModalContent,
    ModalHeader,
    ModalOverlay,
    VStack,
    useDisclosure,
} from "@chakra-ui/react"
import dynamic from "next/dynamic"
import Link from "next/link"

const OverlayOne = () => <ModalOverlay bg="none" backdropFilter="blur(10px) " />

const CardComponent = (props) => {
    const [overlay, setOverlay] = useState(<OverlayOne />)
    const { isOpen, onOpen, onClose } = useDisclosure()
    const dynamicStyle = {
        backgroundColor: props.condition ? "#A06D22" : "#348D8D",
    }
    console.log(props.icon.props.src);

    return (
        <div className=" w-full flex justify-center mt-10 ">
            <div className="transition-all ease-out duration-500  hover:shadow-xl hover:scale-105  flex h-60 w-[56rem]  rounded-2xl relative bg-gray-950 bg-opacity-50 shadow-lg border-opacity-18">
                <div
                    className=" font-semibold font-montserrat tracking-wider absolute bottom-0 origin-bottom-left left-6 transform -rotate-90 text-white w-60  text-center rounded-t-2xl"
                    style={dynamicStyle}
                >
                    {props.label}
                </div>
                <div
                    className=" hover:cursor-pointer"
                    onClick={() => {
                        setOverlay(<OverlayOne />)
                        onOpen()
                    }}
                >
                    <div className="ml-24 mt-12">{props.icon}</div>
                    <div className="flex gap-3 ml-24 mt-12">
                        <h3 className=" font-montserrat font-semibold text-white text-xl">
                            {props.title}
                        </h3>

                        {props.assets}
                    </div>
                </div>
                <VStack
                    spacing={6}
                    align="stretch"
                    className="absolute top-10 right-32 font-montserrat text-md font-medium"
                >
                    {props.showDiscount && (
                        <h3 className="text-white">
                            Discount : <span className="text-red-500">{props.discount}</span>
                        </h3>
                    )}
                    {props.showPremium && (
                        <h3 className="text-white">
                            Discount : <span className="text-green-500">{props.premium}</span>
                        </h3>
                    )}
                    <h3 className="text-white">
                        Price : <span className="text-green-600">{props.price}</span>
                    </h3>
                    <h3 className="text-white">
                        Total Tokens : <span>{props.ttokens}</span>
                    </h3>
                    <h3 className="text-white">
                        Total Value : <span>{props.tvalue}</span>
                    </h3>
                </VStack>
                <div className="absolute right-7 top-24 rounded-full hover:bg-gray-500 hover:cursor-pointer  h-14 w-14 ">
                    <Link
                        href={`/confirmswap?id=${props.rfs.id}`}
                        onClick={() => {
                            window.localStorage.setItem("rfsIdSelected", props.rfs.id)
                            window.localStorage.setItem("currentSelectedPrice", props.rawPrice)
                        }}
                    >
                        <ArrowForwardIcon
                            className="mt-3 ml-3 hover:cursor-pointer "
                            w={8}
                            h={8}
                            color="white"
                        />
                    </Link>
                </div>
            </div>
            <Modal isCentered isOpen={isOpen} onClose={onClose} size={"xl"}>
                {overlay}
                <ModalContent style={{ backgroundColor: "#2D2D2E", color: "white" }}>
                    <ModalHeader>Swap details</ModalHeader>
                    <ModalCloseButton />
                    <ModalBody>
                        <p>
                            You can get coin {props.rfs.token0Data.symbol} for the following coins:{" "}
                            {props.rfs.tokensAcceptedData.map((token) => token.symbol).join(", ")}.
                            You are free to fill only a part of the user’s request.
                        </p>
                        <p>
                            <br />
                            Coin offered:
                        </p>
                        <ul>
                            <li>
                                <img
                                    src={props.rfs.token0Data.logoURI}
                                    alt=""
                                    width="22"
                                    height="22"
                                    style={{ display: "inline-block" }}
                                />{" "}
                                &nbsp;
                                {props.rfs.token0Data.symbol}&nbsp;&nbsp;
                                <a
                                    target={"_blank"}
                                    href={
                                        "https://etherscan.io/token/" + props.rfs.token0Data.address
                                    }
                                >
                                    {props.rfs.token0Data.address}
                                </a>
                            </li>
                        </ul>
                        <br />
                        <p>Coin accepted:</p>
                        <ul>
                            {props.rfs.tokensAcceptedData.map((token, index) => (
                                <li key={index} name={token.name}>
                                    <img
                                        src={token.logoURI}
                                        alt=""
                                        width="20"
                                        height="20"
                                        style={{ display: "inline-block" }}
                                    />
                                    &nbsp;
                                    {token.symbol}&nbsp;&nbsp;
                                    <a
                                        target={"_blank"}
                                        href={"https://etherscan.io/token/" + token.address}
                                    >
                                        {token.address}
                                    </a>
                                </li>
                            ))}
                        </ul>
                        <br />
                        {props.rfs.effectiveType === "DYNAMIC" && (
                            <>
                                <p>
                                    The prices of coins fluctuates and are backed by market value of
                                    this trading pair.
                                </p>
                                {props.showDiscount && props.rfs.priceMultiplier != 100 && (
                                    <p>
                                        The maker of the swap chose to discount this purchase with{" "}
                                        {props.discount}% for you. It means you will pay for the
                                        coin <b>below</b> market price
                                    </p>
                                )}
                                {props.showPremium && (
                                    <p>
                                        The maker of the swap chose to demand {props.premium}%
                                        premium for his/her coins. It means you will pay for the
                                        coin <b>above</b> market price.
                                    </p>
                                )}
                            </>
                        )}
                        {props.rfs.effectiveType === "FIXED_USD" && (
                            <p>The price for each coin is fixed to ${props.rfs.usdPrice} </p>
                        )}
                        {props.rfs.effectiveType === "FIXED_AMOUNT" && (
                            <p>
                                The user chose to swap {props.rfs.initialAmount0} of{" "}
                                {props.rfs.token0Data.symbol} to {props.rfs.amount1} of{" "}
                                {props.rfs.tokensAcceptedData[0].symbol}.
                                <br />
                                <br />
                                <WarningIcon className="mr-3" w={4} h={4} color="lightskyblue" />
                                Note - you can swap a fraction of this request and you are free to
                                fill the whole request.
                            </p>
                        )}
                        <br />
                        <hr />
                        <br />

                        {props.rfs.interactionType === 0 && (
                            <p>
                                The creator of the swap request <b>deposited</b> his/ her coins. It
                                means once you confirm the swap the coins will move.
                            </p>
                        )}
                        {props.rfs.interactionType === 1 && (
                            <p>
                                <WarningIcon className="mr-3" w={4} h={4} color="lightskyblue" />
                                Note The creator of the swap request <b>approved</b> the contract to
                                spend his/ her coins. It means you will need to pay some gas to try
                                to move creator’s coins. It is possible that creator do not have
                                those coins now and swapping will not succeed.
                            </p>
                        )}
                    </ModalBody>
                </ModalContent>
            </Modal>
        </div>
    )
}
export default dynamic(() => Promise.resolve(CardComponent), { ssr: false })
