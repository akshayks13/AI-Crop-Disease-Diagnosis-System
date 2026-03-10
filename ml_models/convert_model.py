import tensorflow as tf
import os
import keras

# Define paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "Disease_Classification_v1.keras")
MODEL_PATH_V2 = os.path.join(BASE_DIR, "Disease_Classification_v2.keras")
TFLITE_PATH = os.path.join(BASE_DIR, "disease_model.tflite")
OUTPUT_PATH_V2 = os.path.join(
    BASE_DIR, "..", "backend", "app", "ml_models",
    "Disease_Classification_v2_noflex.tflite"
)
LABELS_PATH = os.path.join(BASE_DIR, "labels.txt")

# Disease labels (86 classes)
LABELS = [
    'apple_apple_scab', 'apple_black_rot', 'apple_cedar_apple_rust', 'bean_angular_leaf_spot', 
    'bean_rust', 'bell_pepper_bacterial_spot', 'cherry_powdery_mildew', 'corn_cercospora_leaf_spot', 
    'corn_common_rust', 'corn_gray_leaf_spot', 'corn_northern_leaf_blight', 'cotton_aphids', 
    'cotton_army_worm', 'cotton_bacterial_blight', 'cotton_powdery_mildew', 'cotton_target_spot', 
    'diseased_cucumber', 'diseased_rice', 'grape_black_rot', 'grape_esca_black_measles', 
    'grape_leaf_blight', 'groundnut_early_leaf_spot', 'groundnut_late_leaf_spot', 
    'groundnut_nutrition_deficiency', 'groundnut_rust', 'guava_anthracnose', 'guava_fruit_fly', 
    'healthy_apple', 'healthy_bean', 'healthy_bell_pepper', 'healthy_cherry', 'healthy_corn', 
    'healthy_cotton', 'healthy_cucumber', 'healthy_grape', 'healthy_groundnut', 'healthy_guava', 
    'healthy_lemon', 'healthy_peach', 'healthy_potato', 'healthy_pumpkin', 'healthy_rice', 
    'healthy_strawberry', 'healthy_sugarcane', 'healthy_tomato', 'healthy_wheat', 'lemon_anthracnose', 
    'lemon_bacterial_blight', 'lemon_citrus_canker', 'lemon_curl_virus', 'lemon_deficiency', 
    'lemon_dry_leaf', 'lemon_sooty_mould', 'lemon_spider_mites', 'peach_bacterial_spot', 
    'potato_early_blight', 'potato_late_blight', 'pumpkin_bacterial_leaf_spot', 'pumpkin_downy_mildew', 
    'pumpkin_mosaic_disease', 'pumpkin_powdery_mildew', 'strawberry_leaf_scorch', 
    'sugarcane_bacterial_blight', 'sugarcane_mosaic', 'sugarcane_red_rot', 'sugarcane_rust', 
    'sugarcane_yellow_leaf_disease', 'tomato_bacterial_spot', 'tomato_early_blight', 
    'tomato_late_blight', 'tomato_septoria_leaf_spot', 'tomato_yellow_leaf_curl_virus', 
    'wheat_aphid', 'wheat_black_rust', 'wheat_blast', 'wheat_brown_rust', 'wheat_common_root_rot', 
    'wheat_fusarium_head_blight', 'wheat_leaf_blight', 'wheat_mildew', 'wheat_mite', 'wheat_septoria', 
    'wheat_smut', 'wheat_stem_fly', 'wheat_tan_spot', 'wheat_yellow_rust'
]

def convert_model():
    print(f"TensorFlow Version: {tf.__version__}")
    
    print(f"Loading model from {MODEL_PATH}...")
    try:
        # Load model using TFSMLayer (better for v3 models in v2 environment)
        # or recreate the model architecture if needed.
        # But first, let's try the concrete function approach which is most robust.
        
        reloaded_model = tf.keras.models.load_model(MODEL_PATH)
        
        # Convert using the model instance directly
        print("Converting to TFLite...")
        converter = tf.lite.TFLiteConverter.from_keras_model(reloaded_model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        
        tflite_model = converter.convert()
        
        with open(TFLITE_PATH, "wb") as f:
            f.write(tflite_model)
        print(f"TFLite model saved to {TFLITE_PATH}")
        
    except Exception as e:
        print(f"\nStandard conversion failed: {e}\n")
        print("Attempting conversion via Concrete Function...")
        
        try:
            # Fallback: Load as generic trackable object if Keras layer fails
            model = tf.saved_model.load(MODEL_PATH)
            
            # Identify the serving signature
            concrete_func = model.signatures[tf.saved_model.DEFAULT_SERVING_SIGNATURE_DEF_KEY]
            concrete_func.inputs[0].set_shape([1, 224, 224, 3])
            
            converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            tflite_model = converter.convert()
            
            with open(TFLITE_PATH, "wb") as f:
                f.write(tflite_model)
            print(f"TFLite model saved via Concrete Function to {TFLITE_PATH}")
            
        except Exception as e2:
            print(f"Concrete Function conversion failed: {e2}")

    # Save labels regardless (assuming one of them worked or we want them anyway)
    print("Saving labels...")
    with open(LABELS_PATH, "w") as f:
        for label in LABELS:
            f.write(label + "\n")
    print(f"Labels saved to {LABELS_PATH}")

def _force_float32(layer):
    """Recursively set every layer's dtype policy to float32."""
    try:
        layer.dtype_policy = "float32"
    except Exception:
        pass
    if hasattr(layer, "layers"):
        for sub in layer.layers:
            _force_float32(sub)


def convert_v2_no_flex():
    """
    Convert Disease_Classification_v2.keras → a flex-free TFLite.

    Root cause of FlexPad in the existing compressed TFLite:
      The v2 model bakes resnet50.preprocess_input as a Sequential layer
      (index 1), which emits FlexPad ops.  ml_service already applies the
      same preprocessing externally, so we can skip that layer entirely.

    Root cause of tf.MatMul / tf.AddV2 in previous conversion attempts:
      Every internal layer was saved with dtype_policy='mixed_float16'.
      mixed_float16 causes Keras 3 to trace matmuls/adds as TF-dialect f16
      ops instead of native tfl.fully_connected / tfl.add.
      Fix: recursively reset all dtype_policies to float32 BEFORE building
      the new model so every op traces as float32 → native TFLite.

    Output: backend/app/ml_models/Disease_Classification_v2_noflex.tflite
    """
    import tempfile, shutil

    print(f"TensorFlow Version: {tf.__version__}")
    print(f"Loading {MODEL_PATH_V2} ...")
    model = tf.keras.models.load_model(MODEL_PATH_V2, compile=False)
    # Model layers: [0=Input, 1=Sequential(preprocess)←SKIP, 2=ResNet50, 3..=head]

    # ------------------------------------------------------------------
    # Force float32 on every layer (including deep inside ResNet50).
    # The model was trained with mixed_float16; without this step Keras 3
    # traces all ops as tf.MatMul(f16) / tf.AddV2(f16) — all Flex ops.
    # ------------------------------------------------------------------
    print("Forcing float32 dtype policy on all layers ...")
    for layer in model.layers:
        _force_float32(layer)

    # Rebuild: Input → ResNet50 (layer 2) → head (layers 3+), skipping layer 1
    print("Rebuilding model without preprocess layer ...")
    inp = tf.keras.Input(shape=(224, 224, 3), dtype=tf.float32, name="input_image")
    x   = model.layers[2](inp)
    # ResNet50 may return multiple outputs (feature map + aux); take the first
    if isinstance(x, (list, tuple)):
        x = x[0]
    for layer in model.layers[3:]:
        x = layer(x)
        if isinstance(x, (list, tuple)):
            x = x[0]

    new_model = tf.keras.Model(inputs=inp, outputs=x)
    print(f"Rebuilt model output shape: {new_model.output_shape}")

    tflite = None

    tmpdir = tempfile.mkdtemp()
    try:
        print("Exporting to SavedModel ...")
        saved_path = os.path.join(tmpdir, "saved_model")
        new_model.export(saved_path)
        converter = tf.lite.TFLiteConverter.from_saved_model(saved_path)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        tflite = converter.convert()
        print("SavedModel → TFLite succeeded.")
    except Exception as e:
        print(f"SavedModel route failed: {e}")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

    if tflite is None:
        try:
            print("Trying from_keras_model fallback ...")
            converter2 = tf.lite.TFLiteConverter.from_keras_model(new_model)
            converter2.optimizations = [tf.lite.Optimize.DEFAULT]
            converter2.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
            tflite = converter2.convert()
            print("from_keras_model succeeded.")
        except Exception as e2:
            print(f"from_keras_model also failed: {e2}")

    if tflite is None:
        print("\nAll conversion routes failed — see errors above.")
        return

    out = os.path.abspath(OUTPUT_PATH_V2)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "wb") as f:
        f.write(tflite)
    print(f"\nSUCCESS: {out}  ({len(tflite)/1024/1024:.1f} MB)")
    print("\nNext steps:")
    print("  git add backend/app/ml_models/Disease_Classification_v2_noflex.tflite")
    print("  git commit -m 'feat: add flex-free TFLite v2'")
    print("  git push")


if __name__ == "__main__":
    convert_v2_no_flex()
