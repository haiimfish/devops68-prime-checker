provider "azurerm" {
  features {}
}

# 1. สร้าง Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. ระบบ Network (VNet & Subnet)
resource "azurerm_virtual_network" "vnet" {
  name                = "app-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 3. Network Security Group (Firewall)
resource "azurerm_network_security_group" "nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "App_Port"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.app_port # ใช้พอร์ต 3006 จาก variables.tf
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 4. สร้าง MySQL Flexible Server และการตั้งค่า
resource "azurerm_mysql_flexible_server" "db" {
  name                   = "mysql-server-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = "mysqladmin"
  administrator_password = var.db_password
  sku_name               = "B_Standard_B1ms"
  zone                   = var.zone
}

# ไม้ตาย: ปิด SSL เพื่อให้แอปเชื่อมต่อได้ง่าย
resource "azurerm_mysql_flexible_server_configuration" "disable_ssl" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db.name
  value               = "OFF"
}

# สร้าง Database ตามชื่อที่ระบุใน variables.tf
resource "azurerm_mysql_flexible_database" "main_db" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_all" {
  name                = "AllowAll"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# 5. สร้าง Public IP (Static) และ Network Interface
resource "azurerm_public_ip" "pip" {
  name                = "app-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 6. สร้าง Virtual Machine พร้อมติดตั้งซอฟต์แวร์ (Custom Data)
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "devops68-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = "ubuntu"
  zone                            = var.zone
  disable_password_authentication = true # ใช้ SSH Key ตาม variables.tf

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # 1. บันทึก Log เพื่อตรวจสอบย้อนหลัง
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    # 2. ติดตั้งพื้นฐานและ Node.js 20
    apt-get update -y
    apt-get install -y curl
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs

    # 3. เตรียมโฟลเดอร์สำหรับแอปพลิเคชัน
    mkdir -p /home/ubuntu/prime-checker
    cd /home/ubuntu/prime-checker

    # 4. เริ่มต้นโปรเจกต์และติดตั้ง Express
    npm init -y
    npm install express

    # 5. สร้างไฟล์ server.js (บรรจุ Logic การเช็คเลข Prime)
    cat <<'APP_EOF' > server.js
    const express = require("express");
    const app = express();

    // Logic: ตรวจสอบเลขเฉพาะ (Prime Number)
    function isPrime(num) {
        if (num <= 1) return false;
        for (let i = 2; i <= Math.sqrt(num); i++) {
            if (num % i === 0) return false;
        }
        return true;
    }

    // Endpoint ตามที่อาจารย์ต้องการ: GET /check?number=x
    app.get("/check", (req, res) => {
        const num = parseInt(req.query.number);
        if (isNaN(num)) {
            return res.status(400).json({ error: "Please provide a valid number" });
        }
        res.json({
            number: num,
            isPrime: isPrime(num)
        });
    });

    // กำหนดพอร์ตตามตัวแปร Terraform หรือใช้ 3006 เป็นค่าเริ่มต้น
    const port = ${var.app_port};
    app.listen(port, () => console.log("Prime Checker is running on port " + port));
    APP_EOF

    # 6. รันแอปพลิเคชันไว้เบื้องหลัง (Background Process)
    nohup node server.js > app.log 2>&1 &
  EOF
  )
}

# ส่วนประกอบสนับสนุน (SSH Key, Random Suffix)
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/azure_vm_key.pem"
  file_permission = "0600"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}