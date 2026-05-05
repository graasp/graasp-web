defmodule Admin.Validation.PredictionDraw do
  @moduledoc """
  Draws detected objects on an image. Provides functionality to filter detected objects by class and add optional descriptions to the image.
  """
  alias Admin.Validation.PredictionColors
  @stroke_width 3
  @description_label_font_size 21
  @class_label_font_size 18

  @doc """
  Draws a rectangle around detected objects in the image and adds class labels.

  ## Parameters

    - image: The original image where objects are detected.
    - detected_objects: A list of maps containing detection information such as bounding box and class index.
    - options: A keyword list of options. Supported options:
      - :description - An optional description to be added to the image.
      - :classes - A list of classes to filter the detected objects. This can be a list of class indices or class names (e.g., "person", "bicycle").

  ## Returns

  The image with drawn rectangles and class labels for detected objects.
  """
  @spec draw_detected_objects(
          image :: Vix.Vips.Image.t(),
          detected_objects :: [map()],
          options :: Keyword.t()
        ) :: Vix.Vips.Image.t()
  def draw_detected_objects(image, detected_objects, options \\ []) do
    width = Vix.Vips.Image.width(image)

    description = Keyword.get(options, :description)
    classes = Keyword.get(options, :classes)

    # filter detected objects by classes
    detected_objects =
      if classes do
        Enum.filter(detected_objects, fn detection ->
          detection.class in classes or detection.class_idx in classes
        end)
      else
        detected_objects
      end

    # draw detected objects
    image_with_detections =
      Enum.reduce(detected_objects, image, &draw_object_detection(&2, &1, width))

    # add description label
    if description do
      # creating description label
      desc_label = description_label_image(description)

      {full_width, full_height, _} = Image.shape(image)
      {desc_width, desc_height, _} = Image.shape(desc_label)

      Image.Draw.image!(
        image_with_detections,
        desc_label,
        full_width - desc_width,
        full_height - desc_height
      )
    else
      image_with_detections
    end
  end

  defp draw_object_detection(image, %{bbox: bbox} = detection, width) do
    left = max(round((bbox.cx - bbox.w / 2) * width), 0)
    top = max(round((bbox.cy - bbox.h / 2) * width), 0)
    color = PredictionColors.class_color(detection.class_idx)

    class_label = class_label_image(detection)
    {_, text_height, _} = Image.shape(class_label)

    image
    |> Image.Draw.rect!(left, top, ceil(bbox.w * width), ceil(bbox.h * width),
      stroke_width: @stroke_width,
      color: color,
      fill: false
    )
    |> Image.Draw.image!(class_label, left, max(top - text_height - 2, 0))
  end

  defp class_label_image(detection) do
    color = PredictionColors.class_color(detection.class_idx)
    prob = round(detection.prob * 100)

    Image.Text.simple_text!("#{detection.class} #{prob}%",
      text_fill_color: "white",
      font_size: @class_label_font_size
    )
    |> Image.Text.add_background_padding!(background_fill_color: color, padding: [5, 5])
    |> Image.Text.add_background!(background_fill_color: color)
    |> Image.split_alpha()
    |> elem(0)
  end

  defp description_label_image(text) do
    Image.Text.simple_text!(text,
      text_fill_color: "white",
      font_size: @description_label_font_size
    )
    |> Image.Text.add_background_padding!(background_fill_color: "#0000FF", padding: [5, 5])
    |> Image.Text.add_background!(background_fill_color: "#0000FF")
    |> Image.split_alpha()
    |> elem(0)
  end
end
