"use client"

import styles from "./style"
import '@rainbow-me/rainbowkit/styles.css';
import dynamic from "next/dynamic";
import Feature1 from "./components/Feature1"
import Navbar from "./components/Navbar"
import Hero from "./components/Hero"
import Stats from "./components/Stats"
import Feature3 from "./components/Feature3"
import Feature2 from "./components/Feature2"
import Devs from "./components/Devs"
import Service from "./components/Service"
import Footer from "./components/Footer"
import { ConnectButton } from "@rainbow-me/rainbowkit"

export default function Home() {
  

    return (
    
        <div className="bg-black w-full overflow-hidden ">
    <div className={`${styles.paddingX} ${styles.flexCenter}`}>
      <div className={`${styles.boxWidth}`}>
        <Navbar/>
      </div>
      <div className='h-fit w-60 text-center bg-blue-gradient p-3 pl-4 -mr-50 rounded-xl z-30'>
    <ConnectButton showBalance={false}/>
    </div>
    </div>
    
    <div className={`bg-black ${styles.flexStart}`}>
      <div className={`${styles.boxWidth}`}>
        <Hero/>
      </div>
    </div>
    
    <div className={`bg-black ${styles.paddingX} ${styles.flexCenter}`}>
      <div className={`${styles.boxWidth}`}>
        <Stats/>
        <Feature1/>
        <Feature2/>
        <Feature3/>
        <Devs/>
        <Service/>
        <Footer/>
      </div>
    </div>
  </div>
    )
}
