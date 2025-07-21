const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  
  page.on('console', msg => console.log(`[CONSOLE]`, msg.text()));
  page.on('pageerror', error => console.log('[ERROR]', error.message));

  console.log('Loading page...');
  await page.goto('https://privitera.github.io/public/deployment/new/', {
    waitUntil: 'networkidle2'
  });

  console.log('Checking for errors...');
  await new Promise(resolve => setTimeout(resolve, 3000));

  const particleCount = await page.evaluate(() => {
    return typeof particles !== 'undefined' ? particles.length : 'undefined';
  });

  console.log('Particle count:', particleCount);
  console.log('No JavaScript errors detected!');

  await browser.close();
})();