import React from "react"
import card from "@public/card.png"
import styles, { layout } from "@src/app/style"
import Button from "./Button"
import Image from "next/image"
const Feature3 = () => {
    return (
        <section className={`${layout.section} lg:pl-20`}>
            <div className={layout.sectionInfo}>
                <h2 className={styles.heading2}>
                    Lorem ipsum dolor sit amet, <br className="sm:block hidden" /> consectetur
                    adipiscing elit.
                </h2>
                <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
                    Arcu tortor, purus in mattis at sed integer faucibus. Aliquet quis aliquet eget
                    mauris tortor.ç Aliquet ultrices ac, ametau.
                </p>

                <Button styles={`mt-10`} />
            </div>

            <div className={layout.sectionImg}>
                <Image src={card} alt="billing" className="w-[100%] h-[100%]" />
            </div>
        </section>
    )
}

export default Feature3
