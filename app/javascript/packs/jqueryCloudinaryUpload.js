$(document).ready(function () {
  $(".cloudinary-fileupload")
    .cloudinary_fileupload({
      dropZone: "#drop-zone",
      start: function (e) {
        $("#cloudinary-fileupload-status").removeClass("is-hidden");
        $("#cloudinary-fileupload-message").text("Starting upload...");
      },
      progress: function (e, data) {
        $("#cloudinary-fileupload-progress").val(Math.round((data.loaded * 100.0) / data.total));
        $("#cloudinary-fileupload-message").text(`Uploading... ${Math.round((data.loaded * 100.0) / data.total)}%`);
      },
      fail: function (e, data) {
        $("#cloudinary-fileupload-message").text("Upload failed");
      }
    })
    .off("cloudinarydone").on("cloudinarydone", function (e, data) {
      $("#cloudinary-fileupload-status").addClass("is-hidden");
      var preview = $("#cloudinary-fileupload-preview").html("");
      $.cloudinary.image(data.result.public_id, {
        format: data.result.format, width: 500, height: 500, crop: "fill"
      }).appendTo(preview);

      $("<a/>").
        addClass("delete_by_token delete is-medium").
        attr({ href: "#" }).
        data({ delete_token: data.result.delete_token }).
        html("&times;").
        appendTo(preview).
        click(function (e) {
          e.preventDefault();
          $.cloudinary.delete_by_token($(this).data("delete_token")).done(function () {
            $("#cloudinary-fileupload-preview").html("");
            $("#info").html("");
            $('input[name="image[cl_id]"]').remove();
          }).fail(function () {
            $("#cloudinary-fileupload-status").removeClass("is-hidden");
            $("#cloudinary-fileupload-progress").addClass("is-hidden");
            $("#cloudinary-fileupload-message").text("Cannot delete image");
          });
        });
    });
});
