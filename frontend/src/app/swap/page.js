"use client";
import React from 'react'
import Sidebar from '../components/Sidebar'
import CardComponent from '../components/CardComponent'
import { CardData } from '../components/CardData'
import dynamic from "next/dynamic";

const swap = () => {
  return (
    <div className="flex h-fit w-full bg-gray-black">
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

