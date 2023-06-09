import { VStack } from "@chakra-ui/react"
import { Button } from "antd"
import React from "react"
import { ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import OtcOptionAbi from "@constants/abis/OtcOptionAbi"
import { useToast } from "@chakra-ui/react"

const TakeDealCard = (props) => {
    const toast = useToast()

    const onTakeClick = async () => {
        try {
            const provider = new ethers.providers.Web3Provider(window.ethereum)
            const signer = provider.getSigner()
            const chainId = (await provider.getNetwork()).chainId
            console.log(chainId)
            const contract = new ethers.Contract(
                networkMapping[chainId].OtcOption,
                OtcOptionAbi,
                signer
            )
            const tx = await contract.takeDeal(props.id)
            console.log(tx)
            const receipt = await tx.wait()
            console.log(receipt)
            if (receipt)
                toast({
                    title: "Deal taken!",
                    status: "success",
                    duration: 9000,
                    isClosable: true,
                })
        } catch (e) {
            console.error(e)
            toast({
                title: "There was some error!",
                status: "error",
                duration: 9000,
                isClosable: true,
            })
        }
    }

    const onRemoveClick = async () => {
        try {
            const provider = new ethers.providers.Web3Provider(window.ethereum)
            const signer = provider.getSigner()
            const chainId = (await provider.getNetwork()).chainId
            console.log(chainId)
            const contract = new ethers.Contract(
                networkMapping[chainId].OtcOption,
                OtcOptionAbi,
                signer
            )
            const tx = await contract.removeDeal(props.id)
            console.log(tx)
            const receipt = await tx.wait()
            console.log(receipt)
            if (receipt)
                toast({
                    title: "Deal removed!",
                    status: "success",
                    duration: 9000,
                    isClosable: true,
                })
        } catch (e) {
            console.error(e)
            toast({
                title: "There was some error!",
                status: "error",
                duration: 9000,
                isClosable: true,
            })
        }
    }

    const onSettleClick = async () => {
        try {
            const provider = new ethers.providers.Web3Provider(window.ethereum)
            const signer = provider.getSigner()
            const chainId = (await provider.getNetwork()).chainId
            console.log(chainId)
            const contract = new ethers.Contract(
                networkMapping[chainId].OtcOption,
                OtcOptionAbi,
                signer
            )
            const tx = await contract.settleDeal(props.id)
            console.log(tx)
            const receipt = await tx.wait()
            console.log(receipt)
            if (receipt)
                toast({
                    title: "Deal settled!",
                    status: "success",
                    duration: 9000,
                    isClosable: true,
                })
        } catch (e) {
            console.error(e)
            toast({
                title: "There was some error!",
                status: "error",
                duration: 9000,
                isClosable: true,
            })
        }
    }

    return (
        <div class=" transition-all h-fit ease-out duration-500 border-2 border-[#5ce1e6] hover:shadow-xl hover:scale-105 relative flex flex-col items-center rounded-[20px]  w-[350px]  p-4 bg-gray-950 bg-opacity-50 shadow-lg border-opacity-18  ">
            <div class="relative flex h-32 w-full justify-center rounded-xl bg-cover">
                <img
                    src="https://horizon-tailwind-react-git-tailwind-components-horizon-ui.vercel.app/static/media/banner.ef572d78f29b0fee0a09.png"
                    class="absolute flex h-32 w-full justify-center rounded-xl bg-cover"
                />
                <div class="absolute top-8 flex-col flex items-center justify-center text-gray-black z-10 font-montserrat font-bold">
                    <h3>Deal ID: {props.id}</h3>
                    <h3>Underlying token: {props.underlyingtoken.substring(0, 6)}</h3>
                    <h3>Quote token: {props.quotetoken.substring(0, 6)}</h3>
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
                <Button
                    className="bg-gray-dark border-2 border-gray-black text-gray-400 rounded-md  px-4 top-5 "
                    onClick={onTakeClick}
                >
                    Take
                </Button>
                <Button
                    className="bg-gray-dark border-2 border-gray-black rounded-md px-4 top-5 text-gray-400"
                    onClick={onRemoveClick}
                >
                    Remove
                </Button>
                <Button
                    className="bg-gray-dark border-2 border-gray-black rounded-md  px-4 top-5 text-gray-400"
                    onClick={onSettleClick}
                >
                    Settle
                </Button>
            </div>
        </div>
    )
}

export default TakeDealCard
