defmodule Admin.Validation.NudenetValidation do
  @moduledoc """
  Module for performing validation using the nudenet model on images.
  """

  alias Admin.S3
  alias Admin.Validation.PredictionDraw

  defp model_name, do: Application.app_dir(:admin, "priv/models/320n.onnx")
  defp classes_path, do: Application.app_dir(:admin, "priv/models/labels.json")

  def from_file(s3_path) do
    image = get_image(s3_path)
    detected_objects = perform(image)

    annotated_image =
      PredictionDraw.draw_detected_objects(image, detected_objects)

    {annotated_image, detected_objects}
  end

  def show(s3_path, detected_objects) do
    image = get_image(s3_path)

    PredictionDraw.draw_detected_objects(image, detected_objects)
  end

  def perform(image) do
    model = YOLO.load(model_path: model_name(), classes_path: classes_path(), eps: [:cpu])

    model
    |> YOLO.detect(image,
      iou_threshold: 0.45,
      prob_threshold: 0.25,
      frame_scaler: YOLO.FrameScalers.ImageScaler
    )
    |> YOLO.to_detected_objects(model.classes)
  end

  defp get_image(s3_path) do
    image_bin =
      S3.download(Admin.ItemFiles.bucket(), s3_path)

    Image.from_binary!(image_bin) |> Image.thumbnail!(320) |> Image.split_alpha() |> elem(0)
  end
end
