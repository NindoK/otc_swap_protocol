"use client"

import styles from "./style"

import dynamic from "next/dynamic"
import Feature1 from "@src/app/components/Feature1"
import Navbar from "@src/app/components/Navbar"
import Hero from "@src/app/components/Hero"
import Stats from "@src/app/components/Stats"
import Feature3 from "@src/app/components/Feature3"
import Feature2 from "@src/app/components/Feature2"
import Devs from "@src/app/components/Devs"
import Service from "@src/app/components/Service"
import Footer from "@src/app/components/Footer"
import { ConnectButton } from "@rainbow-me/rainbowkit"

export default function Home() {
    return (
        <div className="bg-black w-full overflow-hidden ">
            <div className={`${styles.paddingX} ${styles.flexCenter}`}>
                <div className={`${styles.boxWidth}`}>
                    <Navbar />
                </div>
                <div className="h-fit w-60 text-center bg-blue-gradient p-3 pl-4 -mr-50 rounded-xl z-30">
                    <ConnectButton showBalance={false} />
                </div>
            </div>

            <div className={`bg-black ${styles.flexStart}`}>
                <div className={`${styles.boxWidth}`}>
                    <Hero />
                </div>
            </div>

            <div className={`bg-black ${styles.paddingX} ${styles.flexCenter}`}>
                <div className={`${styles.boxWidth}`}>
                    <Stats />
                    <Feature1 />
                    <Feature2 />
                    <Feature3 />
                    <Devs />
                    <Service />
                    <Footer />
                </div>
            </div>
        </div>
    )
}
