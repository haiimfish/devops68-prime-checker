# Prime Number Checker API

Check if a number is prime.

## Endpoint

### GET `/check`

**1.เข้าสู่ระบบ:**
```az login     # เข้า Account Azure ของตัวเอง
```

**2.สร้าง Infra**
``` 
terraform init                    # ดาวน์โหลดปลั๊กอิน
terraform plan                    # ตรวจสอบแผนการสร้าง
terraform apply -auto-approve     # ยืนยันการสร้าง (พิมพ์ yes) 
```
**3.รอ 5-10 นาที**

**4.จากนั้นเข้าลิงค์ตาม Example Request: ได้เลยครับ**

**5.หากติดปัญหาให้ลอง กดเลือก VM > เลือก Operations > เลือก Run command > กดที่ RunShellScript**
```จากนั้นพิมพ์คำสั่ง 
sudo fuser -k 3006/tcp       # เพื่อฆ่า port 3006 ให้หมด
cd /home/ubuntu/nodejs-mysql && nohup node --env-file=.env server.js > app.log 2>&1 &  # เพื่อให้ VM กลับมารันใหม่

จากนั้นลองเข้า http://48.193.45.244:3006/check?number=(ตัวเลข) ดูอีกที
```

**Parameters:**
- `number` (required): Integer to check

**Example Request:**
- โดยสามารถเปลี่ยนเลขหลัง check?number=(ตัวเลข) เพื่อเช็คค่า Prime ได้
```
http://48.193.45.244:3006/check?number=17
http://48.193.45.244:3006/check?number=12
```

**Example Response_1:**
```json
{
  "number": 17,
  "isPrime": true
}
```
**Example Response_2:**
```json
{
  "number": 12,
  "isPrime": false
}
```
