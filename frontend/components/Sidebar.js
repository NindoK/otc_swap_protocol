import React from "react"
import dynamic from "next/dynamic"
import Link from "next/link"
import {
  Button,
  Drawer,
  DrawerBody,
  DrawerCloseButton,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerOverlay,
  Input,
  useDisclosure,
} from "@chakra-ui/react"
import Image from "next/image"
import menu from "@public/menu.svg"
const Sidebar = () => {
  const { isOpen, onOpen, onClose } = useDisclosure()
  const btnRef = React.useRef()
  return (
    <>
      <div className=" sm:flex hidden w-72 bg-gray-900 bg-opacity-40 shadow-lg  border-opacity-18  relative  flex-col gap-5">
        <h2 className=" font-montserrat font-normal text-3xl text-center text-white pt-8 tracking-wider">OTC Nexus</h2>
        <ul className=" flex flex-col gap-5 ">
          <Link href="/swap">
            <li className=" border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
              Take RFS
            </li>
          </Link>
          <Link href="/createrfs">
            <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
              Create RFS
            </li>
          </Link>
          <Link href="/takedeal">
            <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
              Take Option
            </li>
          </Link>
          <Link href="/createdeal">
            <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
              Create Option
            </li>
          </Link>
        </ul>
      </div>
      {!isOpen && (
        <div className="sm:hidden pl-3 pt-3 w-full flex justify-start " ref={btnRef} onClick={onOpen}>
          <Image src={menu} alt="menu" className="w-[28px] h-[28px] object-contain" />
        </div>
      )}

      <Drawer
        className=" w-full bg-gray-900 bg-opacity-40 shadow-lg  border-opacity-18  relative"
        isOpen={isOpen}
        placement="left"
        onClose={onClose}
        finalFocusRef={btnRef}
      >
        <DrawerOverlay />
        <DrawerContent className=" w-full bg-gray-900 bg-opacity-40 shadow-lg  border-opacity-18  relative">
          <DrawerCloseButton />
          <DrawerHeader className=" font-montserrat font-normal text-3xl text-center text-white pt-8 tracking-wider">
            OTC Nexus
          </DrawerHeader>

          <DrawerBody>
            <ul className="pt-10 flex flex-col gap-5 ">
              <Link href="/swap">
                <li className="  border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                  Swap
                </li>
              </Link>
              <Link href="/createrfs">
                <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                  Create rfs
                </li>
              </Link>
              <Link href="/createdeal">
                <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                  Take Deal
                </li>
              </Link>
              <Link href="/createdeal">
                <li className="border-b pb-4 text-white text-xl font-bold tracking-wider font-montserrat pl-6 hover:cursor-pointer ">
                  Create Option
                </li>
              </Link>

              <li className=" absolute bottom-6  text-white text-xl font-bold tracking-wider font-montserrat pl-6  hover:cursor-pointer">
                Settings
              </li>
            </ul>
          </DrawerBody>
        </DrawerContent>
      </Drawer>
    </>
  )
}
export default dynamic(() => Promise.resolve(Sidebar), { ssr: false })
