const express = require('express');
const app = express();

function isPrime(n) {
  if (n < 2) return false;
  if (n === 2) return true;
  if (n % 2 === 0) return false;
  for (let i = 3; i * i <= n; i += 2) {
    if (n % i === 0) return false;
  }
  return true;
}

app.get('/check', (req, res) => {
  const { number } = req.query;
  if (!number) return res.status(400).json({ error: 'Missing number parameter' });
  
  const n = parseInt(number);
  if (isNaN(n)) return res.status(400).json({ error: 'Number must be integer' });
  
  const prime = isPrime(n);
  res.json({ number: n, isPrime: prime });
});

app.listen(3006, () => console.log('Prime Checker API on port 3006'));
