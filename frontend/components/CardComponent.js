"use client"
import React, { useState } from "react"
import { ArrowForwardIcon } from "@chakra-ui/icons"
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
import { useRouter } from "next/router"

const OverlayOne = () => <ModalOverlay bg="none" backdropFilter="blur(10px) " />

const CardComponent = (props) => {
    const [overlay, setOverlay] = useState(<OverlayOne />)
    const { isOpen, onOpen, onClose } = useDisclosure()
    const dynamicStyle = {
        backgroundColor: props.condition ? "#A06D22" : "#348D8D",
    }
    const Type = Object.freeze({
        DYNAMIC: 1,
        FIXED_USD: 2,
        FIXED_AMOUNT: 3
    });
    const rfsType = props.rfs.typeRfs ==0? Type.DYNAMIC: props.rfs.usdPrice>0?Type.FIXED_USD: Type.FIXED_AMOUNT;



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
                        console.log(JSON.stringify(props.rfs))
                        console.log(rfsType)
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
                    <Link href="/confirmswap">
                        <ArrowForwardIcon
                            className="mt-3 ml-3 hover:cursor-pointer "
                            w={8}
                            h={8}
                            color="white"
                        />
                    </Link>
                </div>
            </div>
            <Modal isCentered isOpen={isOpen} onClose={onClose}>
                {overlay}
                <ModalContent style={{ backgroundColor: "#2D2D2E", color: "white" }}>
                    <ModalHeader>Modal Title</ModalHeader>
                    <ModalCloseButton />
                    <ModalBody>
                        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
                        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
                        quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
                        consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
                        cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
                        non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
                    </ModalBody>
                </ModalContent>
            </Modal>
        </div>
    )
}
export default dynamic(() => Promise.resolve(CardComponent), { ssr: false })
