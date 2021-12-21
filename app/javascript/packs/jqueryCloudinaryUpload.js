$(document).ready(function () {
  const preview = $("#cloudinary-fileupload-preview");
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
      progress: function (e, data) {
        fileuploadProgress.val(Math.round((data.loaded * 100.0) / data.total));
        fileuploadMessage.text(`Uploading... ${Math.round((data.loaded * 100.0) / data.total)}%`);
      },
      fail: function (e, data) {
        alert("Upload failed");
      }
    })
    .off("cloudinarydone").on("cloudinarydone", function (e, data) {
      fileuploadStatus.addClass("is-hidden");
      fileuploadProgress.val("0");

      const column = $('<div class="column is-2 is-flex"></div>').appendTo(preview.html(""));

      $.cloudinary.image(data.result.public_id, {
        format: data.result.format, width: 500, height: 500, crop: "fill"
      }).appendTo($("<figure>").appendTo(column));

      $("<a/>").
        addClass("delete_by_token delete is-medium").
        attr({ href: "#" }).
        data({ delete_token: data.result.delete_token }).
        html("&times;").
        appendTo(column).
        click(function (e) {
          e.preventDefault();
          $.cloudinary.delete_by_token($(this).data("delete_token")).done(function () {
            column.remove();
            $('input[name="image[cl_id]"]').val("");
          }).fail(function () {
            alert("Cannot delete image");
          });
        });
    });
});
