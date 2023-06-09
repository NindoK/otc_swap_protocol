import React from "react"
import styles from "@src/app/style"
import Button from "./Button"
const Service = () => {
    return (
        <section
            className={`${styles.flexCenter} ${styles.marginY} ${styles.padding} sm:flex-row flex-col bg-black-gradient-2 rounded-[20px] box-shadow`}
        >
            <div className="flex-1 flex flex-col">
                <h2 className={styles.heading2}>Lets Get Started!</h2>
                <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
                Swap ERC-20 tokens seamlessly with our secure and user-friendly protocol. 
                Start swapping with ease and unlock the power of decentralized finance.{" "}
                </p>
            </div>

            <div className={`${styles.flexCenter} sm:ml-10 ml-0 sm:mt-0 mt-10 text-gray-700`}>
                <Button />
            </div>
        </section>
    )
}

export default Service
