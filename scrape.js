const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
    // Launch headless browser
    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    const url = process.env.SCRAPE_URL || 'https://wesalvator.com/pip';

    try {
        await page.goto(url, { waitUntil: 'domcontentloaded' });

        // Extract page title and first heading
        const data = await page.evaluate(() => {
            return {
                title: document.title,
                heading: document.querySelector('h1')?.innerText || 'No heading found'
            };
        });

        // Save data to JSON
        fs.writeFileSync('scraped_data.json', JSON.stringify(data, null, 2));
        console.log('Scraped data saved:', data);
    } catch (error) {
        console.error('Error scraping:', error);
    }

    await browser.close();
})();