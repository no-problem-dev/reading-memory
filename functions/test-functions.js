const axios = require('axios');

async function testSearchByISBN() {
  try {
    const response = await axios.post(
      'https://asia-northeast1-reading-memory.cloudfunctions.net/searchBookByISBN',
      {
        data: {
          isbn: '9784798121963'  // テスト用ISBN
        }
      },
      {
        headers: {
          'Content-Type': 'application/json',
        }
      }
    );
    
    console.log('Search by ISBN Response:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

async function testGetPopularBooks() {
  try {
    const response = await axios.post(
      'https://asia-northeast1-reading-memory.cloudfunctions.net/getPopularBooks',
      {
        data: {
          limit: 5
        }
      },
      {
        headers: {
          'Content-Type': 'application/json',
        }
      }
    );
    
    console.log('Popular Books Response:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

// テスト実行
console.log('Testing Cloud Functions...\n');
console.log('1. Testing searchBookByISBN...');
testSearchByISBN().then(() => {
  console.log('\n2. Testing getPopularBooks...');
  return testGetPopularBooks();
});