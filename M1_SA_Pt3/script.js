document.getElementById("contact-form").addEventListener("submit", function(event) {
    event.preventDefault(); // Prevents the page from refreshing

    let name = document.getElementById("name").value;
    let email = document.getElementById("email").value;
    let message = document.getElementById("message").value;

    if (name && email && message) {
        document.getElementById("response-message").textContent = "Thank you for reaching out!";
        document.getElementById("response-message").style.color = "green";
    } else {
        document.getElementById("response-message").textContent = "Please fill out all fields.";
        document.getElementById("response-message").style.color = "red";
    }
});

function showTab(tab) {
    // Hide all lists
    document.getElementById('skills').style.display = 'none';
    document.getElementById('education').style.display = 'none';
    document.getElementById('work').style.display = 'none';

    // Show the selected tab
    document.getElementById(tab).style.display = 'block';
}

