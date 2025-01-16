const countElement = document.getElementById('txtCount');
const countButton = document.getElementById('btnCount');

let count = 0;

countButton.addEventListener('click', () => {
  count++;

  countElement.textContent = count;
});