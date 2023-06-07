import React from "react"
import dynamic from "next/dynamic"

const Sidebar = () => {
    return (
        <div className=" w-72 bg-gray-900 bg-opacity-40 shadow-lg  border-opacity-18  relative">
            <h2 className=" font-montserrat font-normal text-3xl text-center text-white pt-8 tracking-wider">
                OTC Nexus
            </h2>
            <ul className="pt-10 flex flex-col gap-5 ">
                <li className=" border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                    OTC
                </li>
                <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                    Options
                </li>
                <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                    History
                </li>
                <li className=" absolute bottom-6  text-white text-xl font-bold tracking-wider font-montserrat pl-6  hover:cursor-pointer">
                    Settings
                </li>
            </ul>
        </div>
    )
}
export default dynamic(() => Promise.resolve(Sidebar), { ssr: false })
