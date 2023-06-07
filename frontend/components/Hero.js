import React from "react"
import styles from "@src/app/style"
import robot from "@public/robot.png"
import Image from "next/image"
const Hero = () => {
    return (
        <section id="home" className={`flex md:flex-row lg:pl-28 flex-col ${styles.paddingY}`}>
            <div className={`flex-1 ${styles.flexStart} flex-col xl:px-0 sm:px-16 px-6`}>
                <div className="flex flex-row justify-between items-center w-full">
                    <h1 className="flex-1 font-montserrat font-semibold ss:text-[72px] text-[52px] text-white ss:leading-[100.8px] leading-[75px]">
                        <span className="text-gradient">OTC Swap</span>{" "}
                    </h1>
                </div>

                <h1 className="font-montserrat font-semibold ss:text-[68px] text-[52px] text-white ss:leading-[100.8px] leading-[75px] w-full">
                    Protocol.
                </h1>
                <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
                    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer volutpat
                    consectetur risus, id consectetur sem dictum quis. Nullam vulputate placerat
                    mauris, vitae ultrices quam.
                </p>
            </div>

            <div className={`flex-1 flex ${styles.flexCenter} md:my-0 my-10 relative`}>
                <Image src={robot} alt="billing" className="w-[100%] h-[100%] relative z-[5]" />

                {/* gradient start */}
                <div className="absolute z-[0] w-[80%] h-[55%] top-0 pink__gradient" />
                <div className="absolute z-[1] w-[80%] h-[80%] rounded-full white__gradient bottom-40" />
                <div className="absolute z-[0] w-[90%] h-[70%] right-20 bottom-20 blue__gradient" />
                {/* gradient end */}
            </div>
        </section>
    )
}

export default Hero
