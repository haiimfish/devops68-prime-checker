output "app_public_url" {
  value       = "http://${azurerm_public_ip.pip.ip_address}:${var.app_port}"
  description = "Copy URL นี้ไปเปิดใน Browser เพื่อดูผลลัพธ์"
}