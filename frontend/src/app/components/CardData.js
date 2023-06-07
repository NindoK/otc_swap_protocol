import { Avatar, AvatarGroup } from "@chakra-ui/react"
import React from "react"


export const CardData = [
    {
        condition: true,
        label: "Dynamic",
        icon: (
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2000 2000" width="70" height="70">
                <g fill="#c2a633">
                    <path d="M1024 659H881.12v281.69h224.79v117.94H881.12v281.67H1031c38.51 0 316.16 4.35 315.73-327.72S1077.44 659 1024 659z" />
                    <path d="M1000 0C447.71 0 0 447.71 0 1000s447.71 1000 1000 1000 1000-447.71 1000-1000S1552.29 0 1000 0zm39.29 1540.1H677.14v-481.46H549.48V940.7h127.65V459.21h310.82c73.53 0 560.56-15.27 560.56 549.48 0 574.09-509.21 531.41-509.21 531.41z" />
                </g>
            </svg>
        ),
        title: "DOGE /",
        Discount: "+5%",
        Price: "0.1621",
        TTokens: "4.3M",
        TValue: "1.3M",
        assets: (
            <AvatarGroup spacing={"0.5rem"} size="sm" max={2}>
                <Avatar
                    name="Polygon"
                    src="https://styles.redditmedia.com/t5_mizl8/styles/communityIcon_fbxy5kraav371.png"
                />
                <Avatar
                    name="Fantom"
                    src="https://th.bing.com/th/id/OIP.MM4kIOWdWX4BQVxyEcraUgAAAA?pid=ImgDet&rs=1"
                />
            </AvatarGroup>
        ),
    },
    {
        condition: false,
        label: "Fixed",
        icon: (
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2000 2000" width="70" height="70">
                <g fill="#c2a633">
                    <path d="M1024 659H881.12v281.69h224.79v117.94H881.12v281.67H1031c38.51 0 316.16 4.35 315.73-327.72S1077.44 659 1024 659z" />
                    <path d="M1000 0C447.71 0 0 447.71 0 1000s447.71 1000 1000 1000 1000-447.71 1000-1000S1552.29 0 1000 0zm39.29 1540.1H677.14v-481.46H549.48V940.7h127.65V459.21h310.82c73.53 0 560.56-15.27 560.56 549.48 0 574.09-509.21 531.41-509.21 531.41z" />
                </g>
            </svg>
        ),
        title: "DOGE /",
        Discount: "+5%",
        Price: "0.1621",
        TTokens: "4.3M",
        TValue: "1.3M",
        assets: (
            <AvatarGroup spacing={"0.5rem"} size="sm" max={2}>
                <Avatar
                    name="Ethereum"
                    src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Ethereum-icon-purple.svg/1200px-Ethereum-icon-purple.svg.png"
                />
                <Avatar
                    name="Fantom"
                    src="https://th.bing.com/th/id/OIP.MM4kIOWdWX4BQVxyEcraUgAAAA?pid=ImgDet&rs=1"
                />
            </AvatarGroup>
        ),
    },
    {
        condition: true,
        label: "Dynamic",
        icon: (
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2000 2000" width="70" height="70">
                <g fill="#c2a633">
                    <path d="M1024 659H881.12v281.69h224.79v117.94H881.12v281.67H1031c38.51 0 316.16 4.35 315.73-327.72S1077.44 659 1024 659z" />
                    <path d="M1000 0C447.71 0 0 447.71 0 1000s447.71 1000 1000 1000 1000-447.71 1000-1000S1552.29 0 1000 0zm39.29 1540.1H677.14v-481.46H549.48V940.7h127.65V459.21h310.82c73.53 0 560.56-15.27 560.56 549.48 0 574.09-509.21 531.41-509.21 531.41z" />
                </g>
            </svg>
        ),
        title: "DOGE /",
        Discount: "+5%",
        Price: "0.1621",
        TTokens: "4.3M",
        TValue: "1.3M",
        assets: (
            <AvatarGroup spacing={"0.5rem"} size="sm" max={2}>
                <Avatar
                    name="Ethereum"
                    src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Ethereum-icon-purple.svg/1200px-Ethereum-icon-purple.svg.png"
                />
                <Avatar
                    name="Fantom"
                    src="https://th.bing.com/th/id/OIP.MM4kIOWdWX4BQVxyEcraUgAAAA?pid=ImgDet&rs=1"
                />
                <Avatar
                    name="Polygon"
                    src="https://styles.redditmedia.com/t5_mizl8/styles/communityIcon_fbxy5kraav371.png"
                />
            </AvatarGroup>
        ),
    },
    
]
