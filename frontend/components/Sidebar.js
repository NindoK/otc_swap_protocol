import React from "react"
import dynamic from "next/dynamic"
import Link from "next/link"

const Sidebar = () => {
    return (
        <div className=" w-72 bg-gray-900 bg-opacity-40 shadow-lg  border-opacity-18  relative">
            <h2 className=" font-montserrat font-normal text-3xl text-center text-white pt-8 tracking-wider">
                OTC Nexus
            </h2>
            <ul className="pt-10 flex flex-col gap-5 ">
                <Link href="/swap"><li className=" border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                Swap
            </li></Link>
                <Link href="/createrfs"><li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                Create rfs
            </li></Link >
                <Link href="/createdeal"><li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                Take Deal
            </li></Link>
                <Link href="/createdeal"><li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                Create Option
            </li></Link>
                
                
                
                
                <li className=" absolute bottom-6  text-white text-xl font-bold tracking-wider font-montserrat pl-6  hover:cursor-pointer">
                    Settings
                </li>
            </ul>
        </div>
    )
}
export default dynamic(() => Promise.resolve(Sidebar), { ssr: false })
