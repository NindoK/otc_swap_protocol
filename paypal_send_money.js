const authUrl = "https://api-m.sandbox.paypal.com/v1/oauth2/token"
const base64 = Buffer.from(`${secrets.clientId}:${secrets.clientSecret}`).toString("base64")
//Not good implementation, but for testing purposes it's fine
const uniqueId = Date.now().toString()

const sender_batch_id = `Payouts_${uniqueId}`
const sender_item_id = `Item_${uniqueId}`

const receiver = args[0]
const amount = args[1]
const currency = args[2]

const body_data = {
  grant_type: "client_credentials",
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

let formBody = []
for (let property in body_data) {
  let encodedKey = encodeURIComponent(property)
  let encodedValue = encodeURIComponent(body_data[property])
  formBody.push(encodedKey + "=" + encodedValue)
}
formBody = formBody.join("&")

const responseAuthToken = Functions.makeHttpRequest({
  url: authUrl,
  method: "POST",
  headers: {
    "Content-Type": "application/x-www-form-urlencoded",
    Accept: "application/json",
    "Accept-Language": "en_US",
    Authorization: `Basic ${base64}`,
  },
  data: formBody,
})
const { data } = await responseAuthToken
const { access_token } = data

const response = Functions.makeHttpRequest({
  url: "https://api-m.sandbox.paypal.com/v1/payments/payouts",
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "PayPal-Request-Id": "1111103e-77ad-4196-8a78-5dea2050476a",
    Authorization: `Bearer ${access_token}`,
  },
  data: {
    sender_batch_header: {
      sender_batch_id: sender_batch_id,
      email_subject: "You have a payout!",
      email_message: "You have received a payout! Thanks for using our service!",
    },
    items: [
      {
        recipient_type: "EMAIL",
        amount: { value: amount, currency: currency },
        note: "Thanks for your patronage!",
        sender_item_id: sender_item_id,
        receiver: receiver,
      },
    ],
  },
})

const responseData = await response
const { payout_batch_id } = responseData.data.batch_header
let isPaymentSuccess = 0
while (true) {
  const responseBatch = Functions.makeHttpRequest({
    url: `https://api-m.sandbox.paypal.com/v1/payments/payouts/${payout_batch_id}`,
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${access_token}`,
    },
  })
  const paymentData = await responseBatch
  const { batch_status } = paymentData.data.batch_header
  if (batch_status == "SUCCESS") {
    isPaymentSuccess = 1
    break
  }
  await sleep(2000)
}
if (!isPaymentSuccess) {
  throw new Error("Payment failed")
}
return Functions.encodeString(payout_batch_id)
