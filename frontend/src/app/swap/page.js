"use client"
import React, { useState, useEffect, useCallback } from "react"
import Sidebar from "@components/Sidebar"
import CardComponent from "@components/CardComponent"
import { CardData } from "@components/CardData"
import dynamic from "next/dynamic"
import Navbar from "@components/Navbar"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import CoingeckoCachedResponse from "@constants/coingeckoCachedResponse"
import { ethers } from "ethers"
import networkMapping from "@constants/networkMapping"
import OtcNexusAbi from "@constants/abis/OtcNexusAbi"

import FeedAggregatorMumbaiAbi from "@constants/abis/FeedAggregatorMumbaiAbi"
import mumbaiAddressesFeedAggregators from "@constants/mumbaiAddressesFeedAggregators"
import { Avatar, AvatarGroup } from "@chakra-ui/react"

function formatNumber(num) {
  if (Math.abs(num) >= 1.0e9) {
    return (Math.abs(num) / 1.0e9).toFixed(2) + "B"
  } else if (Math.abs(num) >= 1.0e6) {
    return (Math.abs(num) / 1.0e6).toFixed(2) + "M"
  } else if (Math.abs(num) >= 1.0e3) {
    return (Math.abs(num) / 1.0e3).toFixed(2) + "K"
  } else {
    return Math.abs(num).toFixed(4)
  }
}

const swap = () => {
  const [tokenData, setTokenData] = useState([])
  const [rfsDataAll, setRfsDataAll] = useState([])
  const [cardComponentData, setCardComponentData] = useState([])
  const [chainId, setChainId] = useState(0)

  async function fetchTokenData() {
    //            const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")
    // workaround
    setTokenData(CoingeckoCachedResponse.tokens)
  }

  const retrieveAvailableRfs = useCallback(async () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    const signer = provider.getSigner()
    const chainId = (await provider.getNetwork()).chainId
    setChainId(chainId)
    const contract = new ethers.Contract(networkMapping[chainId].OtcNexus, OtcNexusAbi, signer)
    let rfses = []
    let maxId = await contract.rfsIdCounter()
    for (let i = 1; i < maxId; i++) {
      let rfs = await contract.getRfs(i)
      console.log(rfs.id.toNumber() !== 0)
      if (!rfs.removed && rfs.id.toNumber() !== 0) {
        console.log("Adding rfs: ", rfs)
        rfses.push(rfs)
      }
    }
    setRfsDataAll(rfses)
  }, []) // assuming there are no dependencies. If there are, include them in the array.

  const assembleCardComponentData = async () => {
    function findTokenDataForAddress(address, tokens) {
      let tokensWithCriteria = tokens.filter((token) => token.address == address)
      console.log(tokensWithCriteria)
      console.log(address)
      if (tokensWithCriteria.length != 1) {
        console.log("Wrong amount of tokens found" + tokensWithCriteria)
      }
      return tokensWithCriteria[0]
    }
    function startsWithNumber(str) {
      const regex = /^\d/
      return regex.test(str)
    }
    function trimRfs(rfs) {
      let trimmedRfs = {}

      for (let key in rfs) {
        //              console.log(key)
        if (startsWithNumber(key)) {
          continue
        }
        if (rfs[key]._isBigNumber) {
          // todo deadline might be big, we may want to convert eg let hexString = '0x01f4'; let decimalNumber = parseInt(hexString, 16); because we are passing string
          trimmedRfs[key] = parseInt(rfs[key]._hex, 16)
        } else {
          trimmedRfs[key] = rfs[key]
        }
      }
      const effectiveType = rfs.typeRfs == 0 ? "DYNAMIC" : rfs.usdPrice > 0 ? "FIXED_USD" : "FIXED_AMOUNT"
      trimmedRfs.effectiveType = effectiveType
      return trimmedRfs
    }
    let cards = []

    const cardPromises = rfsDataAll.map(async (rfs) => {
      let trimmedRfs = trimRfs(rfs)
      let token0Data = findTokenDataForAddress(rfs.token0.toLowerCase(), tokenData)
      let tokensAcceptedData = rfs.tokensAccepted.map((address) =>
        findTokenDataForAddress(address.toLowerCase(), tokenData)
      )
      trimmedRfs.token0Data = token0Data
      trimmedRfs.tokensAcceptedData = tokensAcceptedData

      let showDiscount = false
      let showPremium = false
      let discount = ""
      let premium = ""
      // dynamic
      if (rfs.typeRfs == 0 && rfs.priceMultiplier > 0) {
        if (rfs.priceMultiplier === 100) {
          showDiscount = true
          discount = "none"
        } else if (rfs.priceMultiplier < 100) {
          showDiscount = true
          discount = `${100 - rfs.priceMultiplier}%`
        } else {
          showPremium = true
          premium = `${rfs.priceMultiplier - 100}%`
        }
      }
      let price = 0
      let totalValue = 0
      if (chainId === 80001) {
        const provider = new ethers.providers.Web3Provider(window.ethereum)
        const signer = provider.getSigner()

        if (mumbaiAddressesFeedAggregators[token0Data.address]) {
          const contract = new ethers.Contract(
            mumbaiAddressesFeedAggregators[token0Data.address],
            FeedAggregatorMumbaiAbi,
            signer
          )
          const decimals = await contract.decimals()
          const priceWithDecimals = await contract.latestAnswer()
          price = priceWithDecimals.toNumber() / 10 ** decimals
          totalValue = price * ethers.utils.formatUnits(rfs.currentAmount0, token0Data.decimals)
        }
      }

      if (rfs.typeRfs === 0) {
        price = (price * rfs.priceMultiplier) / 100
        totalValue = (totalValue * rfs.priceMultiplier) / 100
      } else {
        if (rfs.usdPrice > 0) {
          price = rfs.usdPrice.toNumber()
          totalValue = rfs.usdPrice * rfs.currentAmount0
        } else {
          totalValue = totalValue > 0 ? totalValue.toFixed(2) : "N/A"
          price = price > 0 ? price : "N/A"
        }
      }

      return {
        condition: true,
        label: rfs.typeRfs === 0 ? "Dynamic" : "Fixed",
        icon: <img src={token0Data.logoURI} alt="" width="70" height="70" />,
        title: token0Data.name + " /",
        showDiscount: showDiscount,
        showPremium: showPremium,
        discount: discount,
        premium: premium,
        price: price !== undefined && price !== "N/A" ? `$ ${formatNumber(price)}` : "N/A",
        rawPrice: price,
        TTokens: ethers.utils.formatUnits(rfs.currentAmount0, token0Data.decimals),
        TValue: totalValue !== undefined && totalValue !== "N/A" ? `$ ${formatNumber(totalValue)}` : "N/A",
        assets: (
          <AvatarGroup spacing={"0.5rem"} size="sm" max={tokensAcceptedData.length}>
            {tokensAcceptedData.map((token, index) => (
              <Avatar key={index} name={token.name} src={token.logo} />
            ))}
          </AvatarGroup>
        ),
        rfs: trimmedRfs,
      }
    })

    cards = await Promise.all(cardPromises)
    setCardComponentData(cards)
  }

  useEffect(() => {
    const fetchData = async () => {
      fetchTokenData()
      await retrieveAvailableRfs()
    }

    fetchData()
  }, [])

  // New useEffect that runs assembleCardComponentData when rfsDataAll state changes
  useEffect(() => {
    const fetchData = async () => {
      await assembleCardComponentData()
    }
    fetchData()
  }, [rfsDataAll])

  return (
    <div className="flex min-h-screen h-fit w-full bg-black">
      {/* gradient start */}
      <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
      <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
      <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />
      {/* gradient end */}
      <Sidebar />

      <div className="w-full flex flex-col ">
        <div className="w-full flex justify-end py-3 pr-2 z-10">
          <ConnectButton />
        </div>
        {cardComponentData.length === 0 ? (
          <div className="flex flex-col items-center justify-center w-full h-full">
            <div className="flex flex-col items-center justify-center">
              <img src="/images/empty.svg" alt="" className="w-1/2" />
              <p className="text-white text-2xl font-bold mt-10">No RFS available</p>
            </div>
          </div>
        ) : (
          <ul className="mt-36 ml-30">
            {cardComponentData.map((val, key) => {
              return (
                <li>
                  <CardComponent
                    key={key}
                    condition={val.condition}
                    label={val.label}
                    icon={val.icon}
                    assets={val.assets}
                    showDiscount={val.showDiscount}
                    showPremium={val.showPremium}
                    discount={val.discount}
                    premium={val.premium}
                    price={val.price}
                    rawPrice={val.rawPrice}
                    ttokens={val.TTokens}
                    tvalue={val.TValue}
                    title={val.title}
                    rfs={val.rfs}
                  />
                </li>
              )
            })}
          </ul>
        )}
      </div>
    </div>
  )
}
export default dynamic(() => Promise.resolve(swap), { ssr: false })
