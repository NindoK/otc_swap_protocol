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
import Navbar from "./components/Navbar"
import Hero from "./components/Hero"
import Stats from "./components/Stats"
import Feature3 from "./components/Feature3"
import Feature2 from "./components/Feature2"
import Devs from "./components/Devs"
import Service from "./components/Service"
import Footer from "./components/Footer"

export default function Home() {
    const [toggle, setToggle] = useState(false)

    return (
    
        <div className="bg-black w-full overflow-hidden ">
    <div className={`${styles.paddingX} ${styles.flexCenter}`}>
      <div className={`${styles.boxWidth}`}>
        <Navbar/>
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
