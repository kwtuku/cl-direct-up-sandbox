const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
const deleteButtons = document.querySelectorAll('.js-delete-image-button');

deleteButtons.forEach((deleteButton) => {
  const image = deleteButton.parentNode;

  deleteButton.addEventListener('click', () => {
    const articleId = deleteButton.dataset.articleId;
    const imageId = deleteButton.dataset.imageId;

    fetch(`/api/v0/articles/${articleId}/images/${imageId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`${response.status} (${response.statusText})`);
        }
        return response.json()
      })
      .then(function () {
        image.remove();
      })
      .catch(error => {
        alert(error);
      });
  });
});
