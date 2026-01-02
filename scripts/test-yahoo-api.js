#!/usr/bin/env node

/**
 * Script de test réel avec l'API Yahoo Finance
 * Teste avec les vraies données de la base de données
 */

const https = require('https');

// Quelques tickers de test de notre base
const testTickers = ['MC.PA', 'OR.PA', 'AIR.PA'];

function fetchYahooData(ticker) {
  return new Promise((resolve, reject) => {
    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${ticker}?interval=1d&range=1d`;

    https.get(url, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed);
        } catch (error) {
          reject(error);
        }
      });
    }).on('error', (error) => {
      reject(error);
    });
  });
}

async function testYahooAPI() {
  console.log('🌐 Test de l\'API Yahoo Finance réelle\n');
  console.log('=' .repeat(60));

  for (const ticker of testTickers) {
    console.log(`\n📊 Test pour ${ticker}...`);

    try {
      const response = await fetchYahooData(ticker);

      if (response.chart && response.chart.result && response.chart.result[0]) {
        const chart = response.chart.result[0];
        const quote = chart.indicators.quote[0];
        const timestamp = chart.timestamp[0];
        const date = new Date(timestamp * 1000).toISOString().split('T')[0];

        console.log(`   ✅ Données reçues:`);
        console.log(`      Date: ${date}`);
        console.log(`      Open: ${quote.open[0]}`);
        console.log(`      Close: ${quote.close[0]}`);
        console.log(`      Volume: ${quote.volume[0]}`);
      } else {
        console.log(`   ❌ Pas de données dans la réponse`);
      }

      // Attendre 2 secondes entre chaque requête (rate limiting)
      await new Promise(resolve => setTimeout(resolve, 2000));

    } catch (error) {
      console.log(`   ❌ Erreur: ${error.message}`);
    }
  }

  console.log('\n' + '=' .repeat(60));
  console.log('✅ Test terminé');
  console.log('\nSi toutes les requêtes ont réussi, le workflow devrait fonctionner !');
}

testYahooAPI();
