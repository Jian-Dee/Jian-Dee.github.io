// Select form, inputs, and message container
const passwordForm = document.getElementById('passwordForm');
const newPassword = document.getElementById('newPassword');
const confirmPassword = document.getElementById('confirmPassword');
const message = document.getElementById('message');

// Event listener for form submission
passwordForm.addEventListener('submit', function (event) {
    event.preventDefault(); // Prevent form submission

    // Get input values
    const newPasswordValue = newPassword.value.trim();
    const confirmPasswordValue = confirmPassword.value.trim();

    // Compare passwords
    if (newPasswordValue === confirmPasswordValue) {
        message.textContent = 'Password successfully changed.';
        message.className = 'success';
    } else {
        message.textContent = 'Passwords do not match. Please try again.';
        message.className = 'error';
    }
});
