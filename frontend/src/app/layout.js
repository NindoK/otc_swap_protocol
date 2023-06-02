"use client"
import { CacheProvider } from "@chakra-ui/next-js"
import "./globals.css"
import { ChakraProvider } from "@chakra-ui/react"
import { Montserrat } from "@next/font/google"

const montserrat = Montserrat({
    subsets: ["latin"],
    weight: ["100", "200", "300", "400", "500", "600", "700", "800", "900"],
    variable: "--font-montserrat",
})

export default function RootLayout({ children }) {
    return (
        <html lang="en">
            <CacheProvider>
                <ChakraProvider>
                    <body className={`${montserrat.variable} font-montserrat`}>{children}</body>
                </ChakraProvider>
            </CacheProvider>
        </html>
    )
}
