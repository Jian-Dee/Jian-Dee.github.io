// Select form, input field, and task list container
const taskForm = document.getElementById('taskForm');
const taskInput = document.getElementById('taskInput');
const taskList = document.getElementById('taskList');

// Array to store tasks
let tasks = [];

// Function to render tasks on the webpage
function renderTasks() {
    // Clear the current list   
    taskList.innerHTML = '';

    // Loop through the tasks array and create list items
    tasks.forEach((task) => {
        const li = document.createElement('li');
        li.textContent = task;

        taskList.appendChild(li);
    });
}

// Function to handle adding a new task
function addTask(event) {
    event.preventDefault(); // Prevent form submission

    const newTask = taskInput.value.trim(); // Get the input value
    if (newTask) {
        tasks.push(newTask); // Add the new task to the array
        renderTasks(); // Update the displayed task list
        taskInput.value = ''; // Clear the input field
    }
}

// Attach the form submit event listener
taskForm.addEventListener('submit', addTask);
