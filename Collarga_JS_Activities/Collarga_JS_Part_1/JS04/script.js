// Select elements from the DOM
const startDateInput = document.getElementById('startDate');
const endDateInput = document.getElementById('endDate');
const calculateButton = document.getElementById('calculateButton');
const resultParagraph = document.getElementById('result');

// Add click event listener to the button
calculateButton.addEventListener('click', () => {
    // Get the values of the date inputs
    const startDateValue = startDateInput.value;
    const endDateValue = endDateInput.value;

    // Validate the input
    if (!startDateValue || !endDateValue) {
        resultParagraph.textContent = 'Please select both dates.';
        resultParagraph.className = "error";
        return;
    }

    // Convert the date strings to Date objects
    const startDate = new Date(startDateValue);
    const endDate = new Date(endDateValue);

    // Check if the start date is after the end date
    if (startDate > endDate) {
        resultParagraph.textContent = 'The start date must be before the end date.';
        resultParagraph.className = "error";
        return;
    }

    // Calculate the difference in time (in milliseconds)
    const differenceInTime = endDate - startDate;

    // Calculate the difference in days
    const differenceInDays = differenceInTime / (1000 * 60 * 60 * 24);

    // Display the result
    resultParagraph.textContent = `The difference is ${differenceInDays} days.`;
    resultParagraph.className = "success";
});
