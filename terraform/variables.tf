variable "location" {
  description = "Region ของ Azure"
  type        = string
  default     = "Indonesia Central"
}

variable "zone" {
  description = "Availability Zone"
  type        = string
  default     = "1"
}

variable "resource_group_name" {
  description = "ชื่อของ Resource Group"
  type        = string
  default     = "devops68-prime-checker"
}

variable "key_name" {
  description = "ชื่อของ SSH Key ใน Azure"
  type        = string
  default     = "my-terraform-key"
}

variable "vm_size" {
  description = "ขนาดของ Azure VM"
  type        = string
  default     = "Standard_D2s_v3" # ปรับตามที่คุณต้องการ
}

variable "db_password" {
  description = "รหัสผ่านสำหรับ MySQL Database"
  type        = string
  default     = "My5ecre7P@ssw0rd!" 
  sensitive   = true 
}

variable "db_name" {
  description = "ชื่อ Schema ของฐานข้อมูล"
  type        = string
  default     = "devops68_demo"
}

variable "table_name" {
  description = "ชื่อของตารางในฐานข้อมูล"
  type        = string
  default     = "users"
}

variable "app_port" {
  description = "พอร์ตที่แอปพลิเคชันจะรัน"
  type        = string
  default     = "3006"
}