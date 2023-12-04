import turicreate as tc
import tensorflow as tf
import os
from icecream import ic
import pickle
import sys

def load_data(data_dir):
    label_path = os.path.join(data_dir, "labels.pkl")
    with open(label_path, "rb") as fin:
        label2ind = pickle.load(fin)
    # add to list of images & Labels
    images = []
    labels = []
    for label, indices in label2ind.items():
        labels += [str(label)] * len(indices)
        for ind in indices:
            img = tc.Image(os.path.join(data_dir, str(ind)+".png"))
            images.append(img)
        # labels.append(str(label))
        # images.append(tc.Image(os.path.join(data_dir, str(indices[0])+".png")))
    assert len(images) == len(labels)
    print(f"-- Load {len(images)} images from: {data_dir}")

    return tc.SFrame({"image":images, "label":labels})

def set_tc_config():
    tc.config.set_num_gpus(-1)
    # tc.config.set_runtime_config("TURI_NUM_GPUS", 1)

    ## increase performance
    # tc.config.set_runtime_config("TURI_FILEIO_MAXIMUM_CACHE_CAPACITY", 2147483648 * 10) # N * 2 GB
    # tc.config.set_runtime_config("TURI_FILEIO_MAXIMUM_CACHE_CAPACITY_PER_FILE", 2147483648 * 5) 
    # tc.config.set_runtime_config("TURI_SFRAME_JOIN_BUFFER_NUM_CELLS", 52428800 * 5)
    # tc.config.set_runtime_config("TURI_SFRAME_GROUPBY_BUFFER_NUM_ROWS", 1048576 * 5)
    # tc.config.set_runtime_config("TURI_SFRAME_FILE_HANDLE_POOL_SIZE", 128 * 3)
    # tc.config.set_runtime_config('TURI_DEFAULT_NUM_PYLAMBDA_WORKERS', 36)

if __name__ == "__main__":
    ic("GPUS:", tf.config.list_physical_devices('GPU'))
    assert len(tf.config.list_physical_devices('GPU')) > 0
    set_tc_config()
    
    print("=========================================================", flush=True)
    data_dir = sys.argv[1] #"../data/dog_p_on_g_anno_homog_cropped/train4"
    model_name = sys.argv[2] #os.path.basename(data_dir)
    ic(data_dir, model_name)
    print("-- Run exp:", model_name, flush=True)

    ## load images & labels into SFrame
    train_dataset = load_data(data_dir)

    # train a model
    print("-- Start training")
    # model = tc.one_shot_object_detector.create(train_dataset, 'label') # , max_iterations=2000
    model = tc.one_shot_object_detector.create(train_dataset, 'label')

    # save
    save_dir = f"outputs/{model_name}"
    model.save(f'{save_dir}/one_shot_object_detector.model')
    model.export_coreml(f'{save_dir}/MyCustomOneShotDetector.mlmodel')
    print("-- Save at", save_dir)