import tensorflow as tf
import numpy as np
from PIL import Image

# --------------------------------------------------
# CONFIG
# --------------------------------------------------
MODEL_PATH = r"C:\Users\Sekaran\Downloads\plant_disease_fp16.tflite"
IMAGE_PATH = r"C:\Users\Sekaran\Downloads\powdery-mildew-leaf-pumpkin-powdery-mildew-leaf-pumpkin-garden-plant-diseases-159416060.webp"
IMG_SIZE = (224, 224)

class_names = [
    'apple_apple_scab', 'apple_black_rot', 'apple_cedar_apple_rust',
    'bean_angular_leaf_spot', 'bean_rust', 'bell_pepper_bacterial_spot',
    'cherry_powdery_mildew', 'corn_cercospora_leaf_spot',
    'corn_common_rust', 'corn_gray_leaf_spot',
    'corn_northern_leaf_blight', 'cotton_aphids',
    'cotton_army_worm', 'cotton_bacterial_blight',
    'cotton_powdery_mildew', 'cotton_target_spot',
    'diseased_cucumber', 'diseased_rice',
    'grape_black_rot', 'grape_esca_black_measles',
    'grape_leaf_blight', 'groundnut_early_leaf_spot',
    'groundnut_late_leaf_spot', 'groundnut_nutrition_deficiency',
    'groundnut_rust', 'guava_anthracnose', 'guava_fruit_fly',
    'healthy_apple', 'healthy_bean', 'healthy_bell_pepper',
    'healthy_cherry', 'healthy_corn', 'healthy_cotton',
    'healthy_cucumber', 'healthy_grape', 'healthy_groundnut',
    'healthy_guava', 'healthy_lemon', 'healthy_peach',
    'healthy_potato', 'healthy_pumpkin', 'healthy_rice',
    'healthy_strawberry', 'healthy_sugarcane',
    'healthy_tomato', 'healthy_wheat',
    'lemon_anthracnose', 'lemon_bacterial_blight',
    'lemon_citrus_canker', 'lemon_curl_virus',
    'lemon_deficiency', 'lemon_dry_leaf',
    'lemon_sooty_mould', 'lemon_spider_mites',
    'peach_bacterial_spot', 'potato_early_blight',
    'potato_late_blight', 'pumpkin_bacterial_leaf_spot',
    'pumpkin_downy_mildew', 'pumpkin_mosaic_disease',
    'pumpkin_powdery_mildew', 'strawberry_leaf_scorch',
    'sugarcane_bacterial_blight', 'sugarcane_mosaic',
    'sugarcane_red_rot', 'sugarcane_rust',
    'sugarcane_yellow_leaf_disease',
    'tomato_bacterial_spot', 'tomato_early_blight',
    'tomato_late_blight', 'tomato_septoria_leaf_spot',
    'tomato_yellow_leaf_curl_virus',
    'wheat_aphid', 'wheat_black_rust', 'wheat_blast',
    'wheat_brown_rust', 'wheat_common_root_rot',
    'wheat_fusarium_head_blight', 'wheat_leaf_blight',
    'wheat_mildew', 'wheat_mite', 'wheat_septoria',
    'wheat_smut', 'wheat_stem_fly', 'wheat_tan_spot',
    'wheat_yellow_rust'
]

# --------------------------------------------------
# Load TFLite model
# --------------------------------------------------
interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()

input_index = interpreter.get_input_details()[0]["index"]
output_index = interpreter.get_output_details()[0]["index"]

# --------------------------------------------------
# Load and preprocess image
# --------------------------------------------------
img = Image.open(IMAGE_PATH).convert("RGB")
img = img.resize(IMG_SIZE)

img_array = np.array(img).astype(np.float32)
img_array = np.expand_dims(img_array, axis=0)  # (1, 224, 224, 3)

# --------------------------------------------------
# Run inference
# --------------------------------------------------
interpreter.set_tensor(input_index, img_array)
interpreter.invoke()

predictions = interpreter.get_tensor(output_index)[0]  # shape: (num_classes,)

# --------------------------------------------------
# Top-3 Predictions
# --------------------------------------------------
top_3_indices = np.argsort(predictions)[-3:][::-1]
top_3_scores = predictions[top_3_indices]

print("\nTop 3 Predictions:")
for rank, (idx, score) in enumerate(zip(top_3_indices, top_3_scores), start=1):
    print(
        f"{rank}. {class_names[idx]} "
        f"(confidence: {score * 100:.2f}%)"
    )
