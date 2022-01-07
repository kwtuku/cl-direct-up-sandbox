$(document).ready(function () {
  const previews = $("#cloudinary-fileupload-previews");
  const fileuploadStatus = $("#cloudinary-fileupload-status");
  const fileuploadProgress = $("#cloudinary-fileupload-progress");
  const fileuploadMessage = $("#cloudinary-fileupload-message");
  const maxNumberOfFiles = 10;
  let displayedValidationErrorMessages = [];
  let processedFilesCounter = 0;
  let uploadedFilesCounter = 0;

  $(".cloudinary-fileupload")
    .cloudinary_fileupload({
      acceptFileTypes: /(\.|\/)(jpe?g|png|webp)$/i,
      maxFileSize: 2000000,
      getNumberOfFiles: function () { return uploadedFilesCounter; },
      maxNumberOfFiles: maxNumberOfFiles,
      messages: {
        acceptFileTypes: 'jpg, jpeg, png, webpファイルのみがアップロードできます',
        maxFileSize: '2MB以下のファイルがアップロードできます',
        maxNumberOfFiles: `画像は最大で${maxNumberOfFiles}枚までアップロードできます`
      },
      dropZone: "#drop-zone",
      change: function (e, data) {
        if (data.files.length > maxNumberOfFiles) {
          alert(`画像は最大で${maxNumberOfFiles}枚までアップロードできます`);
          return false;
        }
      },
      processalways: function (e, data) {
        const errorMessage = data.files[0].error;

        if (data.files.error && displayedValidationErrorMessages.indexOf(errorMessage) === -1) {
          alert(errorMessage);
          displayedValidationErrorMessages.push(errorMessage);
        }

        if (!data.files.error) {
          uploadedFilesCounter++;
        }

        processedFilesCounter++;

        if (processedFilesCounter === data.originalFiles.length) {
          displayedValidationErrorMessages = [];
          processedFilesCounter = 0;
        }
      },
      start: function (e) {
        fileuploadStatus.removeClass("is-hidden");
        fileuploadMessage.text("アップロードを開始...");
      },
      progressall: function (e, data) {
        let progressAllValue = Math.round((data.loaded * 100.0) / data.total);

        fileuploadProgress.val(progressAllValue);
        fileuploadMessage.text(`アップロード中... ${progressAllValue}%`);
        if (progressAllValue === 100) {
          fileuploadStatus.addClass("is-hidden");
          fileuploadProgress.val("0");
        }
      },
      fail: function (e, data) {
        alert("アップロードに失敗しました");
      }
    })
    .off("cloudinarydone").on("cloudinarydone", function (e, data) {
      const preview = $('<div class="column is-one-fifth is-flex"></div>').appendTo(previews);
      const publicId = data.result.public_id;

      $.cloudinary.image(publicId, {
        format: data.result.format, width: 500, height: 500, crop: "fill"
      }).appendTo($("<figure>").appendTo(preview));

      $(`input[value*="${publicId}"]`).attr('name', `article[image_attributes][${new Date().valueOf()}][cl_id]`);

      $("<a/>").
        addClass("delete_by_token delete is-medium").
        attr({ href: "#" }).
        data({ delete_token: data.result.delete_token }).
        html("&times;").
        appendTo(preview).
        click(function (e) {
          e.preventDefault();
          $.cloudinary.delete_by_token($(this).data("delete_token")).done(function () {
            preview.remove();
            $(`input[value*="${publicId}"]`).remove();

            uploadedFilesCounter--;
          }).fail(function () {
            alert("画像が削除できません");
          });
        });
    });
});
