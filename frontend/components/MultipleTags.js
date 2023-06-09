import { AddIcon } from "@chakra-ui/icons"
import { Box, Flex, IconButton, Select, Tag, TagCloseButton, TagLabel } from "@chakra-ui/react"
import axios from "axios"
import { ethers } from "ethers"
import React, { useEffect, useState } from "react"
import coinGeckoCachedResponse from "@constants/coingeckoCachedResponse.json"

const MultipleTags = ({ setTokensAccepted }) => {
    const [inputValue, setInputValue] = useState("")
    const [tags, setTags] = useState([])
    const [tokenData, setTokenData] = useState([])

    async function fetchTokenData() {
        try {
            const provider = new ethers.providers.Web3Provider(window.ethereum)
            const chainId = (await provider.getNetwork()).chainId

            let tokens
            if (coinGeckoCachedResponse) {
                tokens = coinGeckoCachedResponse.tokens
                //Sort them by current chainId first
                tokens = tokens.sort((a, b) => {
                    if (a.chainId === chainId && b.chainId !== chainId) {
                        return -1
                    }
                    if (a.chainId !== chainId && b.chainId === chainId) {
                        return 1
                    }
                    return 0
                })
            } else {
                const response = await axios.get("https://tokens.coingecko.com/uniswap/all.json")

                // Process the response data
                tokens = response.data.tokens
            }
            setTokenData(tokens)
        } catch (error) {
            console.error("Error fetching token data:", error)
        }
    }

    useEffect(() => {
        fetchTokenData()
    }, [])

    const handleInputChange = (event) => {
        setInputValue(event.target.value)
    }

    const handleInputKeyDown = (event) => {
        if (event.key === "Enter" && inputValue.trim() !== "") {
            addTag()
        }
    }

    const handleAddTag = () => {
        if (inputValue.trim() !== "") {
            addTag()
        }
    }

    const addTag = () => {
        const trimmedValue = inputValue.trim()
        // Check if the tag already exists
        if (!tags.includes(trimmedValue)) {
            const updatedTags = [...tags, trimmedValue]
            setTags(updatedTags)
            setTokensAccepted(updatedTags)
        }
        setInputValue("")
    }

    const handleRemoveTag = (tag) => {
        const updatedTags = tags.filter((t) => t !== tag)
        setTags(updatedTags)
        setTokensAccepted(updatedTags)
    }
    return (
        <Flex direction="column" width="300px">
            <Box mb={2}>
                {tags.map((tag, index) => (
                    <Tag key={`${tag}-${index}`} size="md" mr={1} mb={1}>
                        <TagLabel>{tag}</TagLabel>
                        <TagCloseButton onClick={() => handleRemoveTag(tag)} />
                    </Tag>
                ))}
            </Box>

            <Select
                placeholder="Select options"
                isMulti
                size="md"
                value={inputValue}
                onChange={handleInputChange}
                onKeyDown={handleInputKeyDown}
                mt={2}
                required={false}
            >
                {tokenData.slice(0, 20).map((token) => (
                    <option key={`${token.name}-${token.symbol}`} value={token.address}>
                        {token.symbol}
                    </option>
                ))}
            </Select>

            {tags.length < 5 && (
                <button
                    onClick={handleAddTag}
                    disabled={inputValue.trim() === ""}
                    style={{
                        marginTop: "5px",
                        backgroundColor: "green",
                        color: "white",
                        margin: "5px 120px",
                        border: "none",
                        borderRadius: "50px",
                        cursor: "pointer",
                    }}
                >
                    +
                </button>
            )}
        </Flex>
    )
}

export default MultipleTags
