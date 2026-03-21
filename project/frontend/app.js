// const PHP_API = "http://localhost:8000";
// const GO_API = "http://localhost:8080";

const PHP_API = "https://php-api.docker.localhost/"
const GO_API = "https://go-api.docker.localhost/"

let products = []
let cart = {}

async function loadProducts() {

    const res = await fetch(`${PHP_API}/products`)
    products = await res.json()

    const container = document.getElementById("products")
    container.innerHTML = ""

    products.forEach(p => {

        const div = document.createElement("div")

        div.innerHTML = `
        <b>${p.name}</b> - ${p.price} €
        <input type="number" min="0" value="0" onchange="updateQty(${p.id}, this.value)">
        `

        container.appendChild(div)
    })
}

function updateQty(productId, qty) {
    cart[productId] = Number(qty)
}

async function createOrder() {

    const customer = document.getElementById("customer").value

    const items = []

    for (const productId in cart) {

        if (cart[productId] > 0) {

            items.push({
                product_id: Number(productId),
                quantity: cart[productId]
            })

        }
    }

    const body = {
        customer_name: customer,
        items
    }

    await fetch(`${PHP_API}/orders`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
    })

    loadOrders()
}

async function loadOrders() {

    const res = await fetch(`${PHP_API}/orders`)
    const orders = await res.json()

    const container = document.getElementById("orders")
    container.innerHTML = ""

    orders.forEach(o => {

        const div = document.createElement("div")

        div.innerHTML = `
        <b>Commande #${o.id}</b>
        Client: ${o.customer_name}
        Total: ${o.total_amount} €
        Status: ${o.status}
        `

        container.appendChild(div)
    })
}

async function loadStats() {

    const res = await fetch(`${GO_API}/stats/overview`)
    const stats = await res.json()

    const container = document.getElementById("stats")

    container.innerHTML = `
    Commandes: ${stats.orders_count}<br>
    Revenue: ${stats.revenue} €<br>
    Ticket moyen: ${stats.average_basket} €
    `
}

async function init() {

    await loadProducts()
    await loadOrders()
    await loadStats()

}

init()
