const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
const deleteButtons = document.querySelectorAll('.js-delete-image-cache-button');

deleteButtons.forEach((deleteButton) => {
  const imageCache = deleteButton.parentNode;
  const { publicId } = deleteButton.dataset;
  const hiddenInput = document.querySelector(`input[value*="${publicId}"]`);

  deleteButton.addEventListener('click', () => {
    fetch(`/api/v0/admin_cloudinary/${publicId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`${response.status} (${response.statusText})`);
        }
        return response.json();
      })
      .then(() => {
        hiddenInput.remove();
        imageCache.remove();
      })
      .catch((error) => {
        alert(error);
      });
  });
});
