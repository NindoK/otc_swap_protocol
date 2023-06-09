import React, { useState } from "react"

import close from "@public/close.svg"
import menu from "@public/menu.svg"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import Image from "next/image"
import Link from "next/link"
import dynamic from "next/dynamic"

const Navbar = () => {
    const [toggle, setToggle] = useState(false)
    return (
        <nav className="w-full flex py-6 justify-between items-center navbar">
            <Link href="/">
                <h1 className="hover:cursor-pointer font-montserrat font-extrabold text-2xl text-white">
                    OtcNexus
                </h1>
            </Link>
            <ul className="list-none sm:flex hidden justify-end items-center flex-1">
                <Link href="/createrfs">
                    <li className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10 h-fit w-fit py-2 px-4 bg-gray-dark border-4 border-gray-900 rounded-xl transition-all  ease-out duration-500 hover:shadow-xl hover:scale-105">
                        Create RFS
                    </li>
                </Link>
                <Link href="/createdeal">
                    <li className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10 h-fit w-fit py-2 px-4 bg-gray-dark border-4 border-gray-900 rounded-xl transition-all  ease-out duration-500 hover:shadow-xl hover:scale-105">
                        Create A Deal
                    </li>
                </Link>
                <Link href="/swap">
                    <li className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10 h-fit w-fit py-2 px-8 bg-gray-dark border-4 border-gray-900 rounded-xl transition-all  ease-out duration-500 hover:shadow-xl hover:scale-105">
                        Swap
                    </li>
                </Link>
                <Link href="/takedeal">
                    <li className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10 h-fit w-fit py-2 px-4 bg-gray-dark border-4 border-gray-900 rounded-xl transition-all  ease-out duration-500 hover:shadow-xl hover:scale-105">
                        Take a deal
                    </li>
                </Link>
            </ul>

            <div className="sm:hidden flex flex-1 justify-end items-center">
                <Image
                    src={toggle ? close : menu}
                    alt="menu"
                    className="w-[28px] h-[28px] object-contain"
                    onClick={() => setToggle(!toggle)}
                />

                <div
                    className={`${
                        !toggle ? "hidden" : "flex"
                    } p-6 bg-black-gradient absolute top-20 right-0 mx-4 my-2 min-w-[140px] rounded-xl sidebar z-20`}
                >
                    <ul className="list-none flex justify-end items-start flex-1 flex-col">
                        <Link href="/createdeal"><li
                        
                        className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10 "
                    >
                        Create A Deal
                    </li></Link>
                        <Link href="/swap"><li
                        
                        className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10"
                    >
                        Swap
                    </li></Link>
                    </ul>
                </div>
            </div>
        </nav>
    )
}

export default Navbar
