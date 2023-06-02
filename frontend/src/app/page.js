"use client"
import Image from "next/image"
import styles from "./style"
import logo from "../../public/logo.svg"
import close from "../../public/close.svg"
import menu from "../../public/menu.svg"
import robot from "../../public/robot.png"
import { useState } from "react"
import Link from "next/link"
import Feature1 from "./components/Feature1"

export default function Home() {
    const [toggle, setToggle] = useState(false)

    return (
        <div className="h-screen bg-black w-full ">
            <div className={`${styles.paddingX} ${styles.flexCenter}`}>
                <div className={`${styles.boxWidth}`}>
                    <nav className="w-full flex py-6 justify-between items-center navbar">
                        <Image className="w-[124px] h-[32px]" src={logo} alt="logo" />
                        <ul className="list-none sm:flex hidden justify-end items-center flex-1">
                            <Link href="/" className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10 ">
                                Create A Deal
                            </Link>
                            <Link href="/swap" className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-10">
                                Swap
                            </Link>
                        </ul>

                        <div className="sm:hidden flex flex-1 justify-end items-center">
                            <Image
                                src={toggle ? close : menu}
                                alt="menu"
                                className="w-[28px] h-[28px] object-contain"
                                onClick={() => setToggle((prev) => !prev)}
                            />

                            <div
                                className={`${
                                    toggle ? "flex" : "hidden"
                                } p-6 absolute top-20 right-0 mx-4 bg-black-gradient my-2 min-w-[140px] rounded-xl sidebar`}
                            >
                                <ul className="list-none flex flex-col justify-end items-center flex-1">
                                    <li className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-4 ">
                                        Create A Deal
                                    </li>
                                    <li className="font-montserrat font-normal cursor-pointer text-[16px] text-white mr-4">
                                        Swap
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </nav>
                </div>
            </div>

            <div className={`${styles.flexCenter} bg-black w-[100%]`}>
                <div className={`w-full`}>
                <section id="home" className={`flex md:flex-row flex-col ${styles.paddingY}`}>
                <div className={`flex-1 ${styles.flexStart} flex-col xl:px-0 sm:px-16 px-6`}>

                  <div className={`flex flex-row justify-between items-center lg:pl-40 w-full ${styles.paddingX}`}>
                    <h1 className="flex-1 font-poppins font-semibold ss:text-[72px] text-[52px] text-white ss:leading-[100.8px] leading-[75px]">
                      OTC Swap <br className="sm:block hidden" />{" "}
                      <span className="text-gradient">Protocol</span>{" "}
                    </h1>
                    
                  </div>
          
                  <p className={`${styles.paragraph} lg:pl-40  ${styles.paddingX} max-w-[4670px] mt-5`}>
                    Our team of experts uses a methodology to identify the credit cards
                    most likely to fit your needs. We examine annual percentage rates,
                    annual fees.
                  </p>
                </div>
          
                <div className={`flex-1 flex ${styles.flexCenter} md:my-0 my-10 relative lg:ml-60`}>
                  <Image src={robot} alt="billing" className="w-[90%] h-[100%] relative z-[5]" />
          
                  
                </div>
          {/* gradient start */}
          <div className="absolute z-[0] w-[40%] h-[35%] top-0 right-0 pink__gradient" />
          <div className="absolute z-[1] w-[40%] h-[50%] rounded-full right-0 white__gradient bottom-40" />
          <div className="absolute z-[0] w-[50%] h-[50%] right-0 bottom-20 blue__gradient" />
          {/* gradient end */}
              </section>
                    
                        
                </div>
            </div>

            <div className={`${styles.flexStart} bg-black ${styles.paddingX}`}>
                <div className={`${styles.boxWidth}`}>
                     
                  <section className={`${styles.flexCenter} flex-row flex-wrap sm:mb-20 mb-6`}>
                                <div className={`flex-1 flex justify-center items-center flex-row gap-28`}>
                                <div className="flex "><h4 className=" font-montserrat font-semibold xs:text-[40px] text-[30px] xs:leading-[53px] leading-[43px] text-white">3000+</h4>
                                <p className=" mt-3 font-montserrat font-normal xs:text-[420px] text-[15px] xs:leading-[26px] leading-[21px] text-gradient uppercase ml-3">Lorem Ipsum</p>
                                </div>
                                <div className="flex ">
                                <h4 className=" font-montserrat font-semibold xs:text-[40px] text-[30px] xs:leading-[53px] leading-[43px] text-white">3000+</h4>
                                <p className="mt-3 font-montserrat font-normal xs:text-[420px] text-[15px] xs:leading-[26px] leading-[21px] text-gradient uppercase ml-3">Lorem Ipsum</p>
                                </div>
                                <div className="flex ">
                                <h4 className=" font-montserrat font-semibold xs:text-[40px] text-[30px] xs:leading-[53px] leading-[43px] text-white">3000+</h4>
                                <p className="mt-3 font-montserrat font-normal xs:text-[420px] text-[15px] xs:leading-[26px] leading-[21px] text-gradient uppercase ml-3">Lorem Ipsum</p>
                                </div>
                                </div>
                  </section>

                  <Feature1/>

                </div>
            </div>


        </div>
    )
}
