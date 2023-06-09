import React from "react"
import styles, { layout } from "@src/app/style"
import Button from "./Button"
import star from "@public/Star.svg"
import shield from "@public/Shield.svg"
import send from "@public/Send.svg"
import Image from "next/image"

export const features = [
    {
        id: "feature-1",
        icon: star,
        title: "Chainlink Powered",
        
    },
    {
        id: "feature-2",
        icon: shield,
        title: "Counterparty Risk Free",
        
    },
    
]

const FeatureCard = ({ icon, title, content, index }) => (
    <div
        className={`flex flex-row p-6 rounded-[20px] ${
            index !== features.length - 1 ? "mb-6" : "mb-0"
        } feature-card cursor-pointer`}
    >
        <div className={`w-[64px] h-[64px]  rounded-full ${styles.flexCenter} bg-dimBlue`}>
            <Image src={icon} alt="star" className="w-[50%] mb-8 h-[50%] object-contain" />
        </div>
        <div className="flex-1 flex flex-col ml-3">
            <h4 className="font-montserrat font-semibold text-white align-middle text-[18px] leading-[23.4px] mb-1">
                {title}
            </h4>
            
        </div>
    </div>
)

const Feature1 = () => {
    return (
        <section id="features" className={`${layout.section} lg:pl-24`}>
            <div className={layout.sectionInfo}>
                <h2 className={styles.heading2}>
                Simple. Secure. Swift. <br className="sm:block hidden" /> 
                </h2>
                <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
                Experience the future of token swaps with our user-friendly protocol. Integrated with PayPal and powered by Chainlink Functions, we ensure seamless off-chain payments. Trade ERC-20 tokens effortlessly without cumbersome deposit processes. Enjoy a simplified, secure, and swift way to exchange tokens directly on the blockchain.
                </p>

               
            </div>

            <div className={`${layout.sectionImg} flex-col`}>
                {features.map((feature, index) => (
                    <FeatureCard key={feature.id} {...feature} index={index} />
                ))}
            </div>
        </section>
    )
}

export default Feature1
