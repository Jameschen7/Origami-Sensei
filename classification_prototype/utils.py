__all__ = ["load_yaml", "dump_yaml", "untransform", "imshow", "plot_tensor_image_grid"]

import os
import numpy as np
import numpy as np
import matplotlib.pyplot as plt

# pip install ruamel.yaml
from ruamel.yaml import YAML
def load_yaml(filename): # end with .yml or .yaml
    yaml=YAML(typ='safe')
    with open(filename, 'r') as fin:
        # return yaml.safe_load(fin) # standard yaml
        return yaml.load(fin)
def dump_yaml(obj, filename):
    yaml=YAML()
    yaml.default_flow_style = False
    yaml.indent(mapping=2, sequence=4, offset=2)
    # yaml.indent(mapping=4, sequence=6, offset=4) # map for dict, seq for list, offset for -
    with open(filename, 'w') as fout:
        # yaml.safe_dump(obj, fout, default_flow_style=False, indent=4) # standard yaml
        yaml.dump(obj, fout)


## for plotting tensor/np
def untransform(img):
    """
    convert transformed img in tensor to restored numpy array
    """
    img = img.numpy().transpose((1, 2, 0))
    mean = np.array([0.485, 0.456, 0.406])
    std = np.array([0.229, 0.224, 0.225])
    img = std * img + mean
    img = np.clip(img, 0, 1)
    return img

def imshow(img, title=None):
    """ Imshow for transformed Tensor """
    img = untransform(img)
    plt.imshow(img)
    if title is not None:
        plt.title(title)
    # plt.pause(0.001)  # pause a bit so that plots are updated

def plot_tensor_image_grid(img_list, n_per_row, titles=None, 
                           figsize=(15,10), untransform=None):
    """
    plt version of torchvision make_grid (via plt.subplots+untransform)
    + title 
    + figsize
    (can add plt.suptitle outside)

    args:
    img_list: list of img as tensor
    titles: if included, one for each img
    """
    assert len(img_list) > 0
    if titles:
        assert len(img_list) == len(titles)
    n_row = (len(img_list)-1) // n_per_row + 1
    fig, axes = plt.subplots(n_row, n_per_row, figsize=figsize, 
                            squeeze=False, constrained_layout=True)
    for i, img in enumerate(img_list):
        if untransform:
            axes[i//n_per_row, i%n_per_row].imshow(untransform(img))
        else:
            axes[i//n_per_row, i%n_per_row].imshow(img)
        axes[i//n_per_row, i%n_per_row].axis("off")
        if titles:
            axes[i//n_per_row, i%n_per_row].set_title(titles[i])
    for i in range(len(img_list), n_row*n_per_row):
        axes[i//n_per_row, i%n_per_row].axis("off")
