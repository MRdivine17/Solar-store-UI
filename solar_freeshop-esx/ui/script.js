
let cartItemsContainer;
let totalAmount;
let currentShopId = null;

function fetchPlayerNameFromGame() {
  // Tell the client script to get player name from the server
  fetch(`https://${GetParentResourceName()}/getPlayerName`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    }
  }).then(res => res.json())
    .then(data => {
      if (data.playerName) {
        document.getElementById("playerName").innerHTML = `Hello, ${data.playerName}`;
      } else {
        document.getElementById("playerName").innerHTML = `Hello, Customer`;
      }
    }).catch(err => {
      console.error("Error getting name:", err);
    });
}


function renderItems(itemsData) {
  const container = document.getElementById("items");
  container.innerHTML = "";

  Object.entries(itemsData).forEach(([category, items]) => {
    items.forEach(({ name, label, price }) => {
      const card = document.createElement("div");
      card.classList.add("item-card");
      card.setAttribute("data-category", category);

      // Image path is dynamically created from item name
      const imagePath = `images/${name}.png`;

      card.innerHTML = `
        <img src="${imagePath}" alt="${label}" />
        <h3>${label}</h3>
        <p>₹${price}</p>
        <button class="add-btn">Add</button>
      `;

      const addButton = card.querySelector(".add-btn");
      addButton.addEventListener("click", () => addToCart(name, price));

      container.appendChild(card);
    });
  });
}


let cartItems = {};

function addToCart(name, price) {
  if (!cartItems[name]) {
    cartItems[name] = { quantity: 1, price: price };
  } else {
    cartItems[name].quantity += 1;
  }
  updateCartUI();
}


function changeQty(name, change) {
  if (cartItems[name]) {
    cartItems[name].quantity += change;
    if (cartItems[name].quantity <= 0) delete cartItems[name];
    updateCartUI();
  }
}

function filterItems(category) {
  const allItems = document.querySelectorAll('.item-card'); // Adjust the selector if your item class is different

  allItems.forEach(item => {
    if (category === 'all' || item.dataset.category === category) {
      item.style.display = 'block';
    } else {
      item.style.display = 'none';
    }
  });
}

function updateCartUI() {
  if (!cartItemsContainer || !totalAmount) return;

  cartItemsContainer.innerHTML = "";
  let total = 0;

  Object.entries(cartItems).forEach(([name, item]) => {
    const itemTotal = item.quantity * item.price;
    total += itemTotal;

    const cartRow = document.createElement("div");
    cartRow.className = "cart-item";

    const itemName = document.createElement("div");
    itemName.className = "item-name";
    itemName.textContent = name;

    const quantityControls = document.createElement("div");
    quantityControls.className = "quantity-controls";

    const btnMinus = document.createElement("button");
    btnMinus.textContent = "−";
    btnMinus.addEventListener("click", () => changeQty(name, -1));

    const qtySpan = document.createElement("span");
    qtySpan.textContent = item.quantity;

    const btnPlus = document.createElement("button");
    btnPlus.textContent = "+";
    btnPlus.addEventListener("click", () => changeQty(name, 1));

    quantityControls.appendChild(btnMinus);
    quantityControls.appendChild(qtySpan);
    quantityControls.appendChild(btnPlus);

    const itemPrice = document.createElement("div");
    itemPrice.className = "item-price";
    itemPrice.textContent = `₹${itemTotal}`;

    cartRow.appendChild(itemName);
    cartRow.appendChild(quantityControls);
    cartRow.appendChild(itemPrice);

    cartItemsContainer.appendChild(cartRow);
  });

  totalAmount.textContent = total;
}

window.addEventListener("message", (event) => {
  const data = event.data;

  if (data.type === "showBillData") {
    const { customerName, shopName } = data.payload;
    showBill(customerName, shopName);
  }
});

function showBill(customerName, shopName) {
  const billDiv = document.getElementById("bill");
  const billItems = document.getElementById("bill-items");
  const billTotal = document.getElementById("bill-total");
  const date = new Date().toLocaleString();

  document.getElementById("bill-date").textContent = date;
  document.getElementById("bill-customer").textContent = customerName || "N/A";
  document.getElementById("bill-shop").textContent = shopName || "N/A";

  billItems.innerHTML = "";
  let total = 0;

  if (cartItems && typeof cartItems === "object") {
    Object.entries(cartItems).forEach(([name, item]) => {
      const li = document.createElement("li");
      li.textContent = `${name} x${item.quantity} - ₹${item.quantity * item.price}`;
      billItems.appendChild(li);
      total += item.quantity * item.price;
    });
  }

  billTotal.textContent = `₹${total}`;
  billDiv.classList.add("show");
}




function resetCart() {
  for (let key in cartItems) delete cartItems[key];
  updateCartUI();
  document.getElementById("bill").classList.remove("show");
}

function closeBill() {
  document.getElementById("bill").classList.remove("show");
}

document.addEventListener("DOMContentLoaded", () => {
  cartItemsContainer = document.getElementById("cart-items");
  totalAmount = document.getElementById("total-amount");

  document.querySelector(".pay-btn.cash")?.addEventListener("click", () => {
    fetch(`https://${GetParentResourceName()}/completePurchase`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ method: "cash", cart: cartItems })
    }).then(() => {
      resetCart();
      closeBill();
      closeShopUI();
    });
  });

  document.querySelector(".pay-btn.bank")?.addEventListener("click", () => {
    fetch(`https://${GetParentResourceName()}/completePurchase`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ method: "bank", cart: cartItems })
    }).then(() => {
      resetCart();
      closeBill();
      closeShopUI();
    });
  });

  document.querySelector(".close-bill")?.addEventListener("click", closeBill);
  
  document.querySelector(".proceed-btn")?.addEventListener("click", () => {
    const playerName = document.getElementById("playerName")?.textContent || "Customer";
    const shopName = "Shop";
    showBill(playerName, shopName);
  });

  document.querySelectorAll(".sidebar li").forEach(li => {
    li.addEventListener("click", function() {
      document.querySelectorAll(".sidebar li").forEach(item => item.classList.remove("active"));
      this.classList.add("active");
      const category = this.getAttribute("data-category");
      filterItems(category);
    });
  });
});


// ✅ UI opens only via ox_target → openShop event
window.addEventListener("message", function (event) {
  const data = event.data;

  if (data?.action === "openShop") {
    currentShopId = data.shopId;

    fetch(`https://${GetParentResourceName()}/getItems`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ shopId: currentShopId })
    })
    .then(res => res.json())
    .then(items => {
      if (items && Object.keys(items).length > 0) {
        renderItems(items);
        document.querySelector(".shop-container").style.display = "flex"; // Show UI
        document.body.style.display = "flex"; // Ensure body is shown (center using flex)
        document.body.style.cursor = "default"; // Show cursor
      } else {
        console.warn("No items received.");
      }
    });
    fetchPlayerNameFromGame()
  }
});

// 🔒 Close the UI with ESC key
document.addEventListener("keydown", function (event) {
  if (event.key === "Escape") {
    closeShopUI();
  }
});

// 🔒 Close function
function closeShopUI() {
  document.querySelector(".shop-container").style.display = "none"; // Hide container
  document.body.style.display = "none"; // Hide body
  document.body.style.cursor = "none"; // Hide cursor
  fetch(`https://${GetParentResourceName()}/closeShop`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({})
  });
}
