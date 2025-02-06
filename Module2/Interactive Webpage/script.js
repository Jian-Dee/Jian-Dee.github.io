const fetchRandomFact = async () => {
    const url = 'https://uselessfacts.jsph.pl/api/v2/facts/random?language=en';
    
    try {
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        
        const data = await response.json();
        document.getElementById('fact').innerText = data.text;
    } catch (error) {
        console.error('Error fetching fact:', error);
        document.getElementById('fact').innerText = 'Failed to fetch fact.';
    }
};