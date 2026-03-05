
import os
import sys

def test_resolve():
    current_file = os.path.abspath("backend/app/services/ml_service.py")
    services_dir = os.path.dirname(current_file)
    app_dir = os.path.dirname(services_dir)
    backend_dir = os.path.dirname(app_dir)
    repo_root = os.path.dirname(backend_dir)
    
    print(f"current_file: {current_file}")
    print(f"app_dir: {app_dir}")
    
    candidate_dirs = [
        os.path.join(app_dir, "ml_models"),
        os.path.join(backend_dir, "ml_models"),
        os.path.join(repo_root, "ml_models"),
    ]
    
    model_filename = "Disease_Classification_v2_compressed.tflite"
    labels_filename = "labels.txt"
    
    for d in candidate_dirs:
        print(f"\nChecking dir: {d}")
        if not os.path.isdir(d):
            print("  Is NOT a directory")
            continue
        print("  IS a directory")
        model_path = os.path.join(d, model_filename)
        labels_path = os.path.join(d, labels_filename)
        print(f"  Checking model_path: {model_path}")
        print(f"  Model exists: {os.path.exists(model_path)}")
        print(f"  Checking labels_path: {labels_path}")
        print(f"  Labels exist: {os.path.exists(labels_path)}")

if __name__ == "__main__":
    test_resolve()
