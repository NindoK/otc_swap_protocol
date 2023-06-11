const express = require("express")
const path = require("path")
const cors = require("cors")
const fetch = require("node-fetch-commonjs")
const dotenv = require("dotenv")
const { MessageHandler } = require("./MessageHandler")
const { BatchHandler } = require("./BatchHandler")
const axios = require("axios").default
const qs = require("qs")
dotenv.config({ path: path.join(__dirname, "..", ".env") })

const app = express()
const PORT = process.env.PORT || 4000
const INTERVAL_DURATION = 10000

// Middleware for parsing JSON request bodies
app.use(express.json())
// Middleware for enabling CORS requests
app.use(cors())

const messageHandler = new MessageHandler()
const batchHandler = new BatchHandler()

const paypal = require("@paypal/checkout-server-sdk")
// Set up your environment
let clientId = process.env.PAYPAL_CLIENT_ID
let clientSecret = process.env.PAYPAL_CLIENT_SECRET

// This sample uses SandboxEnvironment. In production, use LiveEnvironment
let environment = new paypal.core.SandboxEnvironment(clientId, clientSecret)

let client = new paypal.core.PayPalHttpClient(environment)

app.post("/create-order", async (req, res) => {
  const order = await createOrder()
  res.json(order)
})

app.post("/complete-order", async (req, res) => {
  const { orderID, payerID, facilitatorAccessToken } = req.body
  const order = await completeOrder(orderID, payerID, facilitatorAccessToken)
  res.json(order)
})

async function completeOrder(order_id, payer_id, facilitatorAccessToken) {
  const authUrl = "https://api-m.sandbox.paypal.com/v1/oauth2/token"
  const base64 = Buffer.from(`${clientId}:${clientSecret}`).toString("base64")
  const responseAuthToken = await fetch(authUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "Accept-Language": "en_US",
      Authorization: `Basic ${base64}`,
    },
    body: "grant_type=client_credentials",
  })
  const { access_token } = await responseAuthToken.json()
  console.log(access_token)
  console.log("order_id: ", order_id)
  const response = await fetch(`https://api-m.sandbox.paypal.com/v2/checkout/orders/${order_id}/capture`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "PayPal-Request-Id": "7b92603e-77ed-4896-8f78-5dea2050476a",
      Authorization: `Bearer ${access_token}`,
    },
  })

  const responseData = await response.json()
  // console.log(responseData)
  await createPayout()
}

const createPayout = async function () {
  const authUrl = "https://api-m.sandbox.paypal.com/v1/oauth2/token"
  const base64 = Buffer.from(`${clientId}:${clientSecret}`).toString("base64")
  const responseAuthToken = await fetch(authUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "Accept-Language": "en_US",
      Authorization: `Basic ${base64}`,
    },
    body: "grant_type=client_credentials",
  })
  const { access_token } = await responseAuthToken.json()

  // const response = await fetch("https://api-m.sandbox.paypal.com/v1/payments/payouts", {
  //     method: "POST",
  //     headers: {
  //         "Content-Type": "application/json",
  //         "PayPal-Request-Id": "1111103e-77ad-4196-8a78-5dea2050476a",
  //         Authorization: `Bearer ${access_token}`,
  //     },
  //     body: JSON.stringify({
  //         sender_batch_header: {
  //             sender_batch_id: "Payouts_2020_311407",
  //             email_subject: "You have a payout!",
  //             email_message: "You have received a payout! Thanks for using our service!",
  //         },
  //         items: [
  //             {
  //                 recipient_type: "EMAIL",
  //                 amount: { value: "9.87", currency: "EUR" },
  //                 note: "Thanks for your patronage!",
  //                 sender_item_id: "201403190001",
  //                 receiver: "sb-ow4im25993315@personal.example.com",
  //             },
  //         ],
  //     }),
  // })
  // console.log(await response.json())
  const response = await axios({
    url: "https://api-m.sandbox.paypal.com/v1/payments/payouts",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "PayPal-Request-Id": "1111103e-77ad-4196-8a78-5dea2050476a",
      Authorization: `Bearer ${access_token}`,
    },
    data: {
      sender_batch_header: {
        sender_batch_id: "Payouts_2020_311907",
        email_subject: "You have a payout!",
        email_message: "You have received a payout! Thanks for using our service!",
      },
      items: [
        {
          recipient_type: "EMAIL",
          amount: { value: "9.87", currency: "EUR" },
          note: "Thanks for your patronage!",
          sender_item_id: "201403190001",
          receiver: "sb-ow4im25993315@personal.example.com",
        },
      ],
    },
  })
  console.log(response)
}

// use the orders api to create an order
async function createOrder() {
  const authUrl = "https://api-m.sandbox.paypal.com/v1/oauth2/token"
  const base64 = Buffer.from(`${clientId}:${clientSecret}`).toString("base64")
  const responseAuthToken = await fetch(authUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "Accept-Language": "en_US",
      Authorization: `Basic ${base64}`,
    },
    body: "grant_type=client_credentials",
  })
  const { access_token } = await responseAuthToken.json()

  const response = await fetch("https://api-m.sandbox.paypal.com/v2/checkout/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "PayPal-Request-Id": "1100000-0001-1106-0e40-00030050476a",
      Authorization: `Bearer ${access_token}`,
    },
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [
        {
          reference_id: "f9f80340-38f0-11e8-a467-0ed5f89f718a",
          amount: { currency_code: "EUR", value: "100.00" },
        },
      ],
    }),
  })
  return await response.json()
}

async function getBalance() {
  const authUrl = "https://api-m.sandbox.paypal.com/v1/oauth2/token"
  const base64 = Buffer.from(`${clientId}:${clientSecret}`).toString("base64")
  const responseAuthToken = await fetch(authUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "Accept-Language": "en_US",
      Authorization: `Basic ${base64}`,
    },
    body: "grant_type=client_credentials",
  })
  const { access_token } = await responseAuthToken.json()

  const response = await fetch("https://api-m.sandbox.paypal.com/v1/reporting/balances", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${access_token}`,
    },
  })

  const responseData = await response.json()

  const eurBalance = responseData.balances[0]
  const usdBalance = responseData.balances[1]
}

//[POST] Submit route for adding messages to the batch
//Requires a message and signature in the request body
app.post("/submit", async (req, res) => {
  try {
    const { message, signature } = req.body
    const result = await messageHandler.addMessage(message, signature)
    if (result.success) {
      res.status(200).send("Message submitted")
    } else {
      res.status(400).send(result.message)
    }
  } catch (error) {
    // console.log(error)
    res.status(400).send(error.message)
  }
})

//[GET] Get batch route for getting the current batch
//Used for showing it in the UI
app.get("/get-batch", (req, res) => {
  const batch = messageHandler.getBatch()
  res.status(200).json(batch)
})

//Making it modular to allow exporting for testing
function startApp(intervalDuration) {
  const server = app.listen(PORT, () => {
    console.log(`Relayer service is running on http://localhost:${PORT}`)
  })

  //Interval for sending the batch to the receiver every `intervalDuration`, currently is set to 10 seconds
  const interval = setInterval(async () => {
    const batch = messageHandler.getBatch()
    if (batch.messages.length > 0) {
      try {
        const { success, message } = await batchHandler.sendBatch(batch)
        if (success) {
          console.log(message)
          messageHandler.clearBatch()
        } else {
          console.error(message)
        }
      } catch (error) {
        console.error("Error sending batch", error)
      }
    }
  }, intervalDuration) // Send batch every 10 seconds = 10000
  return { server, interval }
}

module.exports = { app, startApp }

if (require.main === module) {
  startApp(INTERVAL_DURATION)
}
