const countElement = document.getElementById('count');
const countButton = document.getElementById('countButton');

let count = 0;

countButton.addEventListener('click', () => {
    console.log("clicked");
  count++;

  countElement.textContent = count;
});