$(document).ready(function () {
  const previews = $("#cloudinary-fileupload-previews");
  const fileuploadStatus = $("#cloudinary-fileupload-status");
  const fileuploadProgress = $("#cloudinary-fileupload-progress");
  const fileuploadMessage = $("#cloudinary-fileupload-message");

  $(".cloudinary-fileupload")
    .cloudinary_fileupload({
      acceptFileTypes: /(\.|\/)(jpe?g|png|webp)$/i,
      maxFileSize: 2000000,
      dropZone: "#drop-zone",
      processalways: function (e, data) {
        if (data.files.error) alert(data.files[0].error);
      },
      start: function (e) {
        fileuploadStatus.removeClass("is-hidden");
        fileuploadMessage.text("Starting upload...");
      },
      progressall: function (e, data) {
        let progressAllValue = Math.round((data.loaded * 100.0) / data.total);

        fileuploadProgress.val(progressAllValue);
        fileuploadMessage.text(`Uploading... ${progressAllValue}%`);
        if (progressAllValue === 100) {
          fileuploadStatus.addClass("is-hidden");
          fileuploadProgress.val("0");
        }
      },
      fail: function (e, data) {
        alert("Upload failed");
      }
    })
    .off("cloudinarydone").on("cloudinarydone", function (e, data) {
      const preview = $('<div class="column is-one-fifth is-flex"></div>').appendTo(previews);
      const publicId = data.result.public_id;

      $.cloudinary.image(publicId, {
        format: data.result.format, width: 500, height: 500, crop: "fill"
      }).appendTo($("<figure>").appendTo(preview));

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
          }).fail(function () {
            alert("Cannot delete image");
          });
        });
    });
});
