import React from "react"

import styles from "@src/app/style"

import Image from "next/image"

export const footerLinks = [
    {
        title: "Useful Links",
        links: [
            {
                name: "Swap",
                link: "http://localhost:3000/swap",
            },
            {
                name: "Take a Deal",
                link: "http://localhost:3000/takedeal",
            },
            {
                name: "Create a Deal",
                link: "http://localhost:3000/createdeal",
            },
            {
                name: "Create a rfs",
                link: "http://localhost:3000/createrfs",
            },
            
        ],
    },
    
    
]



const Footer = () => {
    return (
        <section className={`${styles.flexCenter} ${styles.paddingY} flex-col`}>
            <div className={`${styles.flexCenter} md:flex-row flex-col mb-8 w-full`}>
                <div className="flex-[1] flex flex-col justify-center ml-72">
                    <h1 className="font-montserrat font-extrabold text-2xl text-white">OTCNexus</h1>
                    <p className={`${styles.paragraph} mt-4 max-w-[312px]`}>
                    Revolutionize token trading with our user-friendly protocol, enabling secure and seamless peer-to-peer transactions on the blockchain.
                    </p>
                </div>

                <div className="flex-[1.5] w-full flex flex-row justify-between flex-wrap md:mt-0 mt-10 ml-40">
                    {footerLinks.map((footerlink) => (
                        <div
                            key={footerlink.title}
                            className={`flex flex-col ss:my-0 my-4 min-w-[150px]`}
                        >
                            <h4 className=" font-montserrat font-medium text-[18px] leading-[27px] text-white">
                                {footerlink.title}
                            </h4>
                            <ul className="list-none mt-4">
                                {footerlink.links.map((link, index) => (
                                    <li
                                        key={link.name}
                                        className={`font-montserrat font-normal text-[16px] leading-[24px] text-gray-500 hover:text-gray-300 hover:font-bold cursor-pointer ${
                                            index !== footerlink.links.length - 1 ? "mb-4" : "mb-0"
                                        }`}
                                    >
                                        {link.name}
                                    </li>
                                ))}
                            </ul>
                        </div>
                    ))}
                </div>
            </div>

            <div className="w-full flex justify-center items-center md:flex-row flex-col pt-6 border-t-[1px] border-t-[#3F3E45]">
                <p className="font-montserrat font-normal text-center text-[18px] leading-[27px] text-white">
                    Copyright Ⓒ 2023 OTC Swap Protocol. All Rights Reserved.
                </p>
                
            </div>
        </section>
    )
}

export default Footer
