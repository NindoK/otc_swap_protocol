import { VStack } from "@chakra-ui/react"
import { Button } from "antd"
import React from "react"

const TakeDealCard = (props) => {
    return (
        <div class=" transition-all h-fit ease-out duration-500 border-2 border-[#5ce1e6] hover:shadow-xl hover:scale-105 relative flex flex-col items-center rounded-[20px]  w-[300px]  p-4 bg-gray-950 bg-opacity-50 shadow-lg border-opacity-18  ">
            <div class="relative flex h-32 w-full justify-center rounded-xl bg-cover">
                <img
                    src="https://horizon-tailwind-react-git-tailwind-components-horizon-ui.vercel.app/static/media/banner.ef572d78f29b0fee0a09.png"
                    class="absolute flex h-32 w-full justify-center rounded-xl bg-cover"
                />
                <div class="absolute top-8 flex-col flex items-center justify-center text-gray-black z-10 font-montserrat font-bold">
                    <h3>Deal ID: {props.id}</h3>
                    <h3>Underlying token: {props.underlyingToken.substring(0, 6)}</h3>
                    <h3>Quote token: {props.quoteToken.substring(0, 6)}</h3>
                </div>
            </div>
            <div class=" flex-row flex justify-between gap-3 mt-1 text-gray-400 z-10 font-montserrat font-semibold text-sm">
                <VStack className="flex text-center">
                    <h4>Strike: {props.strike}</h4>
                    <h4>Maturity: {props.maturity}</h4>
                    <h4>Option Type: {props.optionType}</h4>
                    <h4>Buyer: {props.buyer.substring(0, 6)}....</h4>
                </VStack>
                <VStack className="flex text-center">
                    <h4>Amount: {props.amount}</h4>
                    <h4>Premium: {props.premium}</h4>
                    <h4>Status: {props.status}</h4>
                    <h4>Seller: {props.seller.substring(0, 6)}....</h4>
                </VStack>
            </div>

            <div className=" flex-row flex justify-between gap-3 mb-3">
                <Button className="bg-gray-dark border-2 border-gray-black text-gray-400 rounded-md  px-4 top-5 ">
                    Take
                </Button>
                <Button className="bg-gray-dark border-2 border-gray-black rounded-md px-4 top-5 text-gray-400">
                    Remove
                </Button>
                <Button className="bg-gray-dark border-2 border-gray-black rounded-md  px-4 top-5 text-gray-400">
                    Settle
                </Button>
            </div>
        </div>
    )
}

export default TakeDealCard
