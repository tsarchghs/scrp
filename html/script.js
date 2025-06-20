let currentScreen = null
let currentTransactionType = null
let currentPropertyId = null

// Function to get the parent resource name
function GetParentResourceName() {
  // Implementation to get the parent resource name
  // This is a placeholder implementation
  return "parent-resource-name"
}

// Screen management
function showScreen(screenId) {
  if (currentScreen) {
    document.getElementById(currentScreen).classList.add("hidden")
  }
  document.getElementById(screenId).classList.remove("hidden")
  currentScreen = screenId
}

function hideAllScreens() {
  const screens = document.querySelectorAll(".screen")
  screens.forEach((screen) => screen.classList.add("hidden"))
  currentScreen = null
}

// Character Selection
function showCharacterSelection() {
  showScreen("character-selection")
}

function selectCharacter(characterId) {
  fetch(`https://${GetParentResourceName()}/selectCharacter`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ characterId: characterId }),
  })
  hideAllScreens()
}

// Character Creation
function showCharacterCreation() {
  showScreen("character-creation")
}

document.getElementById("character-form").addEventListener("submit", (e) => {
  e.preventDefault()

  const name = document.getElementById("char-name").value
  const age = Number.parseInt(document.getElementById("char-age").value)
  const gender = Number.parseInt(document.getElementById("char-gender").value)
  const skin = Number.parseInt(document.getElementById("char-skin").value)

  fetch(`https://${GetParentResourceName()}/createCharacter`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name, age, gender, skin }),
  })

  hideAllScreens()
})

// Inventory
function showInventory(items) {
  const inventoryGrid = document.getElementById("inventory-items")
  inventoryGrid.innerHTML = ""

  items.forEach((item) => {
    const itemDiv = document.createElement("div")
    itemDiv.className = "inventory-item"
    itemDiv.innerHTML = `
            <h4>${item.ItemName}</h4>
            <p>x${item.Quantity}</p>
        `
    inventoryGrid.appendChild(itemDiv)
  })

  showScreen("inventory")
}

function closeInventory() {
  hideAllScreens()
  fetch(`https://${GetParentResourceName()}/closeInventory`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  })
}

// ATM
function showATM(cashBalance, bankBalance) {
  document.getElementById("cash-balance").textContent = cashBalance
  document.getElementById("bank-balance").textContent = bankBalance
  showScreen("atm")
}

function showDepositForm() {
  currentTransactionType = "deposit"
  document.getElementById("transaction-form").classList.remove("hidden")
}

function showWithdrawForm() {
  currentTransactionType = "withdraw"
  document.getElementById("transaction-form").classList.remove("hidden")
}

function hideTransactionForm() {
  document.getElementById("transaction-form").classList.add("hidden")
  document.getElementById("amount").value = ""
}

function processTransaction() {
  const amount = Number.parseInt(document.getElementById("amount").value)
  if (!amount || amount <= 0) return

  fetch(`https://${GetParentResourceName()}/bankTransaction`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ type: currentTransactionType, amount: amount }),
  })

  hideTransactionForm()
  closeATM()
}

function closeATM() {
  hideAllScreens()
  fetch(`https://${GetParentResourceName()}/closeATM`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  })
}

// Property
function showPropertyMenu(propertyId, propertyData) {
  currentPropertyId = propertyId
  document.getElementById("property-name").textContent = propertyData.Name
  document.getElementById("property-owner").textContent = propertyData.OwnerID === 0 ? "None" : "Owned"
  document.getElementById("property-price").textContent = propertyData.Price

  const buyButton = document.getElementById("buy-button")
  const enterButton = document.getElementById("enter-button")

  if (propertyData.OwnerID === 0) {
    buyButton.style.display = "block"
    enterButton.style.display = "none"
  } else {
    buyButton.style.display = "none"
    enterButton.style.display = "block"
  }

  showScreen("property-menu")
}

function buyProperty() {
  fetch(`https://${GetParentResourceName()}/buyProperty`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ propertyId: currentPropertyId }),
  })
  closePropertyMenu()
}

function enterProperty() {
  fetch(`https://${GetParentResourceName()}/enterProperty`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ propertyId: currentPropertyId }),
  })
  closePropertyMenu()
}

function closePropertyMenu() {
  hideAllScreens()
  fetch(`https://${GetParentResourceName()}/closePropertyMenu`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  })
}

// Listen for messages from the game
window.addEventListener("message", (event) => {
  const data = event.data

  switch (data.type) {
    case "showCharacterSelection":
      showCharacterSelection()
      break
    case "showInventory":
      showInventory(data.items)
      break
    case "showATM":
      showATM(data.cash, data.bank)
      break
    case "showPropertyMenu":
      showPropertyMenu(data.propertyId, data.propertyData)
      break
    case "hideUI":
      hideAllScreens()
      break
  }
})

// Close UI on Escape
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    hideAllScreens()
    fetch(`https://${GetParentResourceName()}/closeUI`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    })
  }
})
