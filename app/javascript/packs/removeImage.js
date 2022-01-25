const deleteButtons = document.querySelectorAll('.js-delete-image-button');

deleteButtons.forEach((deleteButton) => {
  const image = deleteButton.parentNode;

  deleteButton.addEventListener('click', () => {
    const imageId = deleteButton.dataset.imageId;
    const destroyingImageInput = document.querySelector(`[name="article[image_attributes][${imageId}][_destroy]"]`);

    destroyingImageInput.value = 'true';
    image.remove();
  });
});
