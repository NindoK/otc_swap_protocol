const authUrl = "https://api-m.sandbox.paypal.com/v1/oauth2/token"
const base64 = Buffer.from(`${secrets.clientId}:${secrets.clientSecret}`).toString("base64")

const order_id = args[0]

const body_data = {
  grant_type: "client_credentials",
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
  url: `https://api-m.sandbox.paypal.com/v2/checkout/orders/${order_id}/capture`,
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "PayPal-Request-Id": "7b92603e-77ed-4896-8f78-5dea2050476a",
    Authorization: `Bearer ${access_token}`,
  },
})

const responseData = await response
console.log(responseData)
let isCompleted = 0
if (responseData.data.status === "COMPLETED") {
  isCompleted = 1
} else {
  throw new Error("Payment is not completed")
}
return Functions.encodeString(order_id)
