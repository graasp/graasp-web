defmodule Admin.Validation.NudenetValidation do
  @moduledoc """
  Module for performing validation using the nudenet model on images.
  """

  alias Admin.S3
  alias Admin.Validation.PredictionDraw

  defp model_name, do: Application.app_dir(:admin, "priv/models/320n.onnx")
  defp classes_path, do: Application.app_dir(:admin, "priv/models/labels.json")

  @model_width 320

  def from_file(s3_path) do
    {image, original_image} = get_image(s3_path)
    detected_objects = perform(image)

    annotated_image =
      PredictionDraw.draw_detected_objects(original_image, detected_objects)

    {annotated_image, detected_objects}
  end

  def show(s3_path, detected_objects) do
    {_, original_image} = get_image(s3_path)

    PredictionDraw.draw_detected_objects(original_image, detected_objects)
  end

  def perform(image) do
    model = YOLO.load(model_path: model_name(), classes_path: classes_path(), eps: [:cpu])

    model
    |> YOLO.detect(image,
      iou_threshold: 0.45,
      prob_threshold: 0.25,
      frame_scaler: YOLO.FrameScalers.ImageScaler
    )
    |> to_detected_objects(model.classes)
  end

  defp get_image(s3_path) do
    image_bin =
      S3.download(Admin.ItemFiles.bucket(), s3_path)

    original_image = Image.from_binary!(image_bin)

    {Image.thumbnail!(original_image, 320) |> Image.split_alpha() |> elem(0),
     original_image |> Image.thumbnail!(640) |> Image.split_alpha() |> elem(0)}
  end

  defp to_detected_objects(bboxes, model_classes) do
    Enum.map(bboxes, fn [cx, cy, w, h, prob, class_idx] ->
      class_idx = round(class_idx)

      %{
        prob: prob,
        bbox: %{
          cx: cx / @model_width,
          cy: cy / @model_width,
          w: w / @model_width,
          h: h / @model_width
        },
        class_idx: class_idx,
        class: Map.get(model_classes, class_idx)
      }
    end)
  end
end
