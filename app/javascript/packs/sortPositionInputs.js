import Sortable from 'sortablejs/modular/sortable.core.esm';

const items = document.querySelector('[data-sortable="items"]');

new Sortable(items, {
  animation: 150,
  ghostClass: 'is-invisible',
});

window.addEventListener('submit', () => {
  const keys = Array.from(items.children).map((item) => item.dataset.sortableKey);
  let positionInputs = '';

  keys.forEach((key, index) => {
    positionInputs += `<input type="hidden" value="${index + 1}" name="article[image_attributes][${key}][position]">`;
  });

  items.insertAdjacentHTML('beforeend', positionInputs);
});
