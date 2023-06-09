import React from "react"
import styles, { layout } from "@src/app/style"
import Image from "next/image"
import hero from "@public/hero.png"
const Feature2 = () => {
    return (
        <section id="product" className={`${layout.sectionReverse} lg:pl-24`}>
            <div className={layout.sectionImgReverse}>
                <Image src={hero} alt="logo" className="w-[100%] h-[100%] relative z-[5]" />

                {/* gradient start */}
                <div className="absolute z-[3] -left-80 top-0 w-[90%] h-[80%] rounded-full pink__gradient" />
                <div className="absolute z-[0] w-[90%] h-[50%] -left-96 bottom-0 rounded-full blue__gradient" />
                {/* gradient end */}
            </div>

            <div className={layout.sectionInfo}>
                <h2 className={styles.heading2}>
                Unleash the Potential of Decentralized Finance <br className="sm:block hidden" /> 
                </h2>
                <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
                Step into the world of decentralized finance and unlock its true potential. Our protocol enables you to participate in peer-to-peer trading directly on the blockchain, eliminating intermediaries and counterparty risks. Experience simplicity, transparency, and be part of the decentralized finance revolution.
                </p>
            </div>
        </section>
    )
}

export default Feature2
