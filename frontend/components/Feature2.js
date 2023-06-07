import React from "react"
import styles, { layout } from "@src/app/style"
import Image from "next/image"
import bill from "@public/bill.png"
const Feature2 = () => {
    return (
        <section id="product" className={`${layout.sectionReverse} lg:pl-24`}>
            <div className={layout.sectionImgReverse}>
                <Image src={bill} alt="billing" className="w-[100%] h-[100%] relative z-[5]" />

                {/* gradient start */}
                <div className="absolute z-[3] -left-80 top-0 w-[90%] h-[80%] rounded-full pink__gradient" />
                <div className="absolute z-[0] w-[90%] h-[50%] -left-96 bottom-0 rounded-full blue__gradient" />
                {/* gradient end */}
            </div>

            <div className={layout.sectionInfo}>
                <h2 className={styles.heading2}>
                    Lorem ipsum dolor sit amet, <br className="sm:block hidden" /> consectetur
                    adipiscing elit.
                </h2>
                <p className={`${styles.paragraph} max-w-[470px] mt-5`}>
                    Elit enim sed massa etiam. Mauris eu adipiscing ultrices ametodio aenean neque.
                    Fusce ipsum orci rhoncus aliporttitor integer platea placerat.
                </p>
            </div>
        </section>
    )
}

export default Feature2
