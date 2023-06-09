"use client"
import { CacheProvider } from "@chakra-ui/next-js"
import "./globals.css"
import { ChakraProvider } from "@chakra-ui/react"
import { Montserrat } from "@next/font/google"
import "@rainbow-me/rainbowkit/styles.css"
import {
    getDefaultWallets,
    RainbowKitProvider,
    darkTheme,
    lightTheme,
} from "@rainbow-me/rainbowkit"
import { configureChains, createConfig, WagmiConfig } from "wagmi"
import { arbitrum, goerli, mainnet, optimism, polygon, polygonMumbai } from "wagmi/chains"
import { publicProvider } from "wagmi/providers/public"

const { chains, publicClient, webSocketPublicClient } = configureChains(
    [
        polygonMumbai,
        mainnet,
        polygon,
        optimism,
        arbitrum,
        ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === "true" ? [goerli] : []),
    ],
    [publicProvider()]
)

const { connectors } = getDefaultWallets({
    appName: "RainbowKit App",
    projectId: "YOUR_PROJECT_ID",
    chains,
})

const wagmiConfig = createConfig({
    autoConnect: true,
    connectors,
    publicClient,
    webSocketPublicClient,
})

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
                    <WagmiConfig config={wagmiConfig}>
                        <RainbowKitProvider
                            theme={lightTheme({
                                accentColor: "#623485", //color of wallet  try #703844
                                accentColorForeground: "white", //color of text
                                borderRadius: "large", //rounded edges
                                fontStack: "system",
                            })}
                            coolMode
                            chains={chains}
                        >
                            <body className={`${montserrat.variable} font-montserrat`}>
                                {children}
                            </body>
                        </RainbowKitProvider>
                    </WagmiConfig>
                </ChakraProvider>
            </CacheProvider>
        </html>
    )
}
