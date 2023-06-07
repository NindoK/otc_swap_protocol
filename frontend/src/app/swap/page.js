"use client";
import React from 'react'
import Sidebar from '../components/Sidebar'
import CardComponent from '../components/CardComponent'
import { CardData } from '../components/CardData'
import dynamic from "next/dynamic";
import Navbar from '../components/Navbar';
import { ConnectButton } from '@rainbow-me/rainbowkit';

const swap = () => {
  return (
    
    <div className="flex h-fit w-full bg-black">
    {/* gradient start */}
    <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
    <div className="absolute z-[0] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
    <div className="absolute z-[0] w-[50%] h-[50%] left-0 bottom-40 blue__gradient" />
    {/* gradient end */}
            <Sidebar />
         
            <ul className="mt-36 ml-40">
                {CardData.map((val, key) => {
                    return (
                        <li>
                            <CardComponent
                                key={key}
                                condition={val.condition}
                                label={val.label}
                                icon={val.icon}
                                assets={val.assets}
                                discount={val.Discount}
                                price={val.Price}
                                ttokens={val.TTokens}
                                tvalue={val.TValue}
                                title={val.title}
                            />
                        </li>
                    )
                })}
            </ul>
        </div>
        
  )
}
export default dynamic (() => Promise.resolve(swap), {ssr: false})

